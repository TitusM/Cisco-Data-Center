# 3. Module 2 — SAN/LAN Uplinks (4.2.a)

**Objective:** get traffic off the Fabric Interconnects and onto both the LAN switches and the SAN switches, correctly typed as uplink ports.

Cisco documents three distinct Ethernet uplink roles on a Fabric Interconnect — don't treat them as interchangeable, since UCSM configures and licenses each differently:[^role]

| Role | Carries | Used in this module for |
|---|---|---|
| **Ethernet uplink** | LAN/Ethernet traffic only | Task 2.1, toward N5K-1/N5K-2 |
| **FCoE uplink** | Fibre Channel encapsulated in Ethernet, toward an upstream FCoE-capable switch | Task 4.5's alternative FCoE path (`05-fc-fcoe.md`), not this pod's default |
| **Unified uplink** | Both Ethernet and FC/FCoE traffic on one physical port | Not used in this lab's topology — its N5K-1/2 (LAN) and N5K-3/4 (SAN) roles are already split onto separate physical uplinks |

[^role]: [Cisco UCS Manager Network Management Guide, Release 6.0 — LAN Ports and Port Channels](https://www.cisco.com/c/en/us/td/docs/unified_computing/ucs/ucs-manager/GUI-User-Guides/Network-Mgmt/4-2/b_UCSM_Network_Mgmt_Guide_4_2/b_UCSM_Network_Mgmt_Guide_chapter_01000.html)

## 3.1 Task 2.1 — Ethernet (LAN) Uplinks

![LAN aspect of Nexus DC-1: N5K-1/N5K-2, FI-A/FI-B, and Host highlighted](../assets/topology-lan.png)
*LAN aspect of Nexus DC-1: N5K-1/N5K-2, FI-A/FI-B, and Host highlighted*

On each FI (UCSM: **Equipment > Fabric Interconnects > Fixed Module > Ethernet Ports**), set the ports facing N5K-1/N5K-2 to **Uplink Port**. If more than one physical link per FI, bundle them (see Module 8).

On N5K-1/N5K-2, first create the local VLANs in the switch's own VLAN database (this is separate from the UCSM VLAN objects you created in Module 1, Task 1.1 — matching IDs are what tie the two together, not a shared database). VLAN 10 and 11 are shared, so both N5K uplink interfaces — the one toward FI-A and the one toward FI-B — carry the same Data/Mgmt pair. The one thing that must *not* be shared is the FCoE VLAN: it's bound to that fabric's VSANs (Module 4), so mixing FCoE VLAN 1000 onto the FI-B-facing interface (or 2000 onto the FI-A-facing one) would leak one fabric's SAN traffic onto the other's Ethernet path and defeat the point of keeping the SAN fabrics isolated:

??? "Commands"
    ```text
    vlan 10
      name Data
    vlan 11
      name Mgmt

    ! Toward FI-A
    interface Ethernet1/1
      switchport mode trunk
      switchport trunk allowed vlan 10,11,1000
      no shutdown

    ! Toward FI-B
    interface Ethernet1/2
      switchport mode trunk
      switchport trunk allowed vlan 10,11,2000
      no shutdown
    ```

If N5K-1/N5K-2 run vPC to each FI, see Module 8 for the vPC-specific config.

## 3.2 Task 2.2 — FC/FCoE (SAN) Uplinks

Decide per-FI whether SAN connectivity is **native FC** or **FCoE**. On the FI (UCSM: **Equipment > Fixed Module > FC Ports**, or **Uplink FCoE Interfaces**), set the ports facing N5K-3/N5K-4 to **FC Uplink Port** (or **FCoE Uplink Port**).

Set the FI's global SAN switching mode first, since it gates what an uplink port can do:

**SAN > SAN Cloud > Fabric A > set FC Switching Mode = End Host (default) or Switching.** End-host mode is the far more common exam and production default — it makes the FI behave as an N-Port/NPV-style device toward the core, which is exactly what Module 6 exercises.

## 3.3 Task 2.3 — N5K-Side F Ports

On N5K-3/N5K-4, the ports facing FI-A/FI-B must come up as **F ports** (fabric ports) so the FI can log in as an N-Port. Each fabric's core switch carries both of that fabric's VSANs (Boot + Data) over the same physical uplink, so the trunk allowed-list needs both IDs, not just one. `feature npiv` is **not** configured here — this pod already has it enabled per the Section 1.1 confirm step, and it needs to already be live the moment this F-port trunk comes up:

??? "Commands"
    ```text
    ! N5K-3 (Fabric A core)
    ! feature npiv          — already enabled, confirmed in Section 1.1; not reconfigured here
    vsan database
      vsan 100
      vsan 101
    interface fc1/1
      switchport mode F
      switchport trunk allowed vsan 100,101
      no shutdown

    ! N5K-4 (Fabric B core) — mirrors N5K-3 with Fabric B's VSANs
    ! feature npiv          — already enabled, confirmed in Section 1.1; not reconfigured here
    vsan database
      vsan 200
      vsan 201
    interface fc1/1
      switchport mode F
      switchport trunk allowed vsan 200,201
      no shutdown
    ```

**Verify:**

??? "Commands"
    ```text
    show interface brief
    show flogi database
    show fcns database vsan 100
    show fcns database vsan 101
    ```

You should see the FI's WWPN(s) FLOGI into the fabric as soon as the link and VSAN membership are correct — expect two logins per fabric once Module 1's boot and data vHBAs are both associated (one FLOGI/FDISC per vHBA, both riding the same physical F port).

!!! question "Check yourself"
    Why must `feature npiv` be enabled on N5K-3/N5K-4 even though NPIV itself is the FI's behavior, not the core switch's? (Answer lives in Module 6 — come back to this after that module if it's not obvious yet.) And why was this the one feature you were told to only *confirm* back in Section 1.1, rather than enable fresh like `feature fcoe` or `feature vpc`? And why does adding VSAN 101 to this trunk's allowed-list not require a second physical F port, when adding VSAN 101 to a *blade* required a second vHBA back in Module 1?

## 3.4 Task 2.4 — VLAN Groups

**Objective:** understand VLAN Groups for what Cisco actually documents them as — a mechanism for controlling *which uplinks carry which VLANs*, not a load-balancing or preferred-path tool.

A **VLAN Group** (UCSM: **LAN > LAN Cloud > VLAN Groups**) associates a set of VLANs with specific uplink Ethernet ports or uplink port channels. Cisco's own documented behavior is explicit and important to get right: once a VLAN Group is associated with a chosen set of uplinks, **any uplink not selected for that association stops supporting the VLANs in that group.** This is a restriction, not a preference — there is no "primary path with failover to an unselected uplink" behavior built into the VLAN Group construct itself.[^1]

Because this lab's own VLAN 10/11 are deliberately shared and trunked identically to both Fabric A and Fabric B uplinks (§0.3, Task 2.1) — not split per fabric — actually associating a VLAN Group with only one fabric's uplink here would remove that VLAN from the other fabric's uplink entirely, which is the opposite of this lab's redundancy design. So this task does **not** build a VLAN Group against this lab's real uplinks. Instead:

??? "🔍 Deep Dive — Upstream Disjoint Layer-2 Networks"
    VLAN Groups exist for topologies where the FI's two fabrics genuinely face **different, disjoint upstream Layer-2 networks** — not the shared/redundant design this lab uses. Conceptually:

    ```text
    Upstream Network A
          |
        N5K-A
          |
     FI uplink A
          |
     VLANs assigned to Network A
    ```

    ```text
    Upstream Network B
          |
        N5K-B
          |
     FI uplink B
          |
     VLANs assigned to Network B
    ```

    Here, VLAN Groups ensure the VLANs that only exist on Network A's side are associated only with FI uplink A, and likewise for Network B — because Network A and Network B don't share a Layer-2 domain, a VLAN valid on one has no business appearing on the other's uplink at all. This is what Cisco calls disjoint Layer-2 networking, and it's the actual production use case VLAN Groups solve.[^2]

    This lab's topology is **not** disjoint Layer-2 — N5K-1 and N5K-2 both sit in the same shared LAN domain, and VLAN 10/11 are intentionally common to both. If you want hands-on practice with a real VLAN Group association, you'd need a second, genuinely separate upstream network to point one fabric's uplink at — not something to build against this pod's actual N5K-1/N5K-2 pair.

**Verify (conceptual only, given the above):** **LAN > LAN Cloud > VLAN Groups** — if a VLAN Group is ever associated with a subset of this lab's uplinks, confirm on the N5K side with `show interface trunk` that the *unselected* uplink's allowed-VLAN behavior for that group's VLANs actually reflects the restriction — don't assume the VLAN still passes there.

!!! question "Check yourself"
    If VLAN Group `VG-Data` (VLAN 10) is associated only with the FI-A-facing uplink, what happens to VLAN 10 traffic that would otherwise have used the FI-B-facing uplink — does it fail over, or does that uplink simply stop supporting VLAN 10? What does that imply about using VLAN Groups on a fabric pair that's supposed to stay redundant, like this lab's own VLAN 10/11?

[^1]: [Cisco UCS Manager Network Management Guide, Release 6.0 — VLANs / VLAN Groups](https://www.cisco.com/c/en/us/td/docs/unified_computing/ucs/ucs-manager/GUI-User-Guides/Network-Mgmt/4-2/b_UCSM_Network_Mgmt_Guide_4_2/b_UCSM_Network_Mgmt_Guide_chapter_0110.html): an uplink not selected for association with a VLAN Group stops supporting VLANs that are members of that group.
[^2]: [Cisco UCS Manager Network Management Guide Using the CLI — Upstream Disjointed Layer-2 Networks](https://www.cisco.com/c/en/us/td/docs/unified_computing/ucs/ucs-manager/CLI-User-Guides/Network-Mgmt/4-2/b_cli_ucsm_network_management_guide_4_2/b_CLI_UCSM_Network_Management_Guide_chapter_01010.html)
