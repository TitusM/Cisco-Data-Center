# 8. Module 7 — Trunking (5.1.c)

**Objective:** carry multiple VSANs (SAN side) and multiple VLANs (LAN side) over shared uplinks.

## 8.1 Task 7.1 — VSAN Trunking (SAN)

On the F-port (or F-port-channel, see Module 8) between N5K-3 and FI-A, this lab already carries two VSANs (100 and 101) over the same physical uplink — you configured this back in Module 2, Task 2.3, so this is where you go verify it, not build it fresh:

```text
interface fc1/1
  switchport mode F
  switchport trunk mode on
  switchport trunk allowed vsan 100,101
```

That `100,101` is exactly the scenario a single-VSAN design never has to think about: if you needed to add a third VSAN later, you'd extend the list rather than replace it — `switchport trunk allowed vsan add 300` — since replacing it outright would silently drop the VSANs you left out.

## 8.2 Task 7.2 — VLAN Trunking (LAN)

Already touched in Module 2.1 — revisit it here specifically for trunk *negotiation and allowed-list hygiene*. Each N5K uplink still only carries its own fabric's pair — this is a check, not a widening of the allowed list from Task 2.1:

```text
! Toward FI-A
interface Ethernet1/1
  switchport mode trunk
  switchport trunk allowed vlan 10,11
  spanning-tree port type edge trunk   ! if this faces an FI, not another switch

! Toward FI-B
interface Ethernet1/2
  switchport mode trunk
  switchport trunk allowed vlan 20,21
  spanning-tree port type edge trunk
```

## 8.3 Task 7.3 — FI-Side Trunk Definitions

On the FI: **LAN > VLANs** and **SAN > VSANs** must both explicitly list every ID you expect trunked, and each uplink port/port-channel must have those IDs assigned. UCSM does not auto-trunk an ID just because it exists globally — it must be assigned to the specific uplink.

**Verify:**

```text
show interface trunk
show vsan
show vlan brief
```

!!! question "Check yourself"
    On the LAN side, what NX-OS feature protects a trunk to an FI (a non-switch, non-STP-speaking device) from accidentally being blocked by spanning tree, and why is that setting safe specifically because the far end is an FI?

## 8.4 Task 7.4 — Worked Example: Diagnosing an Uplink VLAN Trunk Mismatch

**Scenario:** some blades in UCS-B have no network connectivity — no DHCP lease, can't ping the default gateway — while other blades in the *same chassis*, on the *same fabric*, are fully functional. This is the single most common LAN-side outage in a UCS pod, precisely because it produces no faults, no link-down, and no errors anywhere in UCSM: it's a silent, VLAN-specific drop at one trunk boundary. Set up this scenario yourself (or just work through it as a dry run): create two extra VLAN objects, `VLAN 30` and `VLAN 40`, under **LAN > LAN Cloud > VLANs** (same procedure as Module 1, Task 1.1), assign them to a couple of test vNIC templates alongside your existing VLAN 10, and deliberately leave them off the upstream N5K trunk's allowed list to reproduce the fault.

1. **Rule out Layer 3 first.** From an affected blade, ping the default gateway directly. 100% loss, with a healthy blade sitting in the next slot, tells you this is scoped — not a general LAN or routing outage — before you touch a single switch command.
2. **Identify which VLAN(s) the affected service profiles actually use.** **Servers > Service Profiles > [name] > Network**, note the vNIC's assigned VLAN — in this drill, the affected blades are the ones on VLAN 30 and VLAN 40, not VLAN 10.
3. **Confirm those VLANs exist and are assigned to the uplink in UCSM.** **LAN > LAN Cloud > VLANs** — confirm VLAN 30/40 are defined, and check that they're assigned to the uplink port/port-channel from Task 2.1.
4. **Check the upstream N5K-1/N5K-2 allowed-list on the specific interface facing that FI:**

    ```text
    show vlan
    show interface trunk
    ```

    If VLAN 30 and 40 exist switch-wide in `show vlan` but are missing from that interface's "Vlans Allowed on Trunk" list in `show interface trunk`, you've found it — the FI is willing to pass VLAN 30/40 frames, but the upstream N5K interface is silently dropping them because its allowed-list doesn't include those IDs. Everything on VLAN 10 keeps working over the exact same physical link, which is why the fault looks so selective.

5. **Fix the allowed list on the affected interface:**

    ```text
    interface Ethernet1/1
      switchport trunk allowed vlan add 30,40
    ```

6. **Verify and confirm recovery:**

    ```text
    show interface trunk
    ```

    Confirm VLAN 30 and 40 now appear in that interface's allowed list, then confirm from the blade side that it obtains a DHCP lease and can reach the default gateway.

!!! question "Check yourself"
    Why does this fault hit only *some* servers on the same chassis, same fabric, and same physical uplink, rather than all of them? Name the one property of a service profile's vNIC that determines whether a given blade is affected — and explain why "some work, some don't" is itself diagnostic evidence that should point you at a VLAN allowed-list before you check anything else.
