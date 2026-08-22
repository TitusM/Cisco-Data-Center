# 9. Module 8 — PortChannel (5.1.d)

**Objective:** bundle physical links for bandwidth and resiliency, on both LAN and SAN sides.

## 9.1 Task 8.1 — Ethernet Port Channel (vPC) on the LAN Side

The LAN-side port channel was already built in Module 2, Task 2.1 — `feature vpc`, the `vpc domain`/peer-keepalive, `interface port-channel1`/`port-channel2` with `vpc 1`/`vpc 2`, and the FI-side **Port Channels** under **LAN > LAN Cloud**. This section is where you go verify and troubleshoot it, not build it fresh.

The one thing worth calling out here that Task 2.1 didn't dwell on: `channel-group N mode active` uses LACP (`active` on both ends negotiates; `active`/`passive` also works, but `passive`/`passive` never comes up since neither side initiates). A member stuck in `(I)` (individual, not bundled) almost always means the two ends disagree on LACP mode, speed, or the port's `switchport mode trunk` state — not a cabling problem, since `(I)` still implies the physical link is up.

## 9.2 Task 8.2 — FC Port Channel (SAN Side)

If more than one FC/FCoE link exists between an FI and its N5K, bundle them into a **SAN Port Channel**. Carry both of that fabric's VSANs on the port channel, same as you did on the single F port back in Module 2, Task 2.3:

??? "Commands"
    ```text
    interface fc1/1-2
      channel-group 1 force
    interface san-port-channel 1
      switchport mode F
      switchport trunk allowed vsan 100,101
    ```

On the FI: **SAN > SAN Cloud > Fabric A > FC Port Channels**, add the member uplinks.

## 9.3 Task 8.3 — Verify

??? "Commands"
    ```text
    show port-channel summary
    show interface port-channel1
    show san-port-channel summary
    ```

Confirm all members show `(P)` (up, in port channel) — a member stuck in `(I)` (individual) or `(D)` (down) means a parameter mismatch (speed, mode, or allowed VSAN/VLAN list) between the two ends.

!!! question "Check yourself"
    What specifically causes an FC port channel member to fail to bundle even though the physical link is up — and how is that different from the Ethernet port-channel case?
