# 9. Module 8 — PortChannel (5.1.d)

**Objective:** bundle physical links for bandwidth and resiliency, on both LAN and SAN sides.

## 9.1 Task 8.1 — Ethernet Port Channel (vPC) on the LAN Side

If N5K-1/N5K-2 form a vPC domain toward each FI, the peer-keepalive link must already be up before the peer-link (port-channel) can form — configure it first, and note it needs its own routed source/destination pair (commonly the mgmt0 VRF), separate from the peer-link data path:

??? "Commands"
    ```text
    ! On both N5K-1 and N5K-2
    feature vpc
    vpc domain 1
      peer-keepalive destination <peer-mgmt-ip> source <this-switch-mgmt-ip> vrf management
    interface port-channel10
      vpc 10
    interface Ethernet1/1
      channel-group 10 mode active
    ```

On the FI side, bundle the corresponding uplink ports into a **Port Channel** under **LAN > LAN Cloud > Fabric A > Port Channels**.

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
    show interface port-channel10
    show san-port-channel summary
    ```

Confirm all members show `(P)` (up, in port channel) — a member stuck in `(I)` (individual) or `(D)` (down) means a parameter mismatch (speed, mode, or allowed VSAN/VLAN list) between the two ends.

!!! question "Check yourself"
    What specifically causes an FC port channel member to fail to bundle even though the physical link is up — and how is that different from the Ethernet port-channel case?
