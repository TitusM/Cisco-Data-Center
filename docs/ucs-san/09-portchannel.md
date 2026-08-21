# 9. Module 8 — PortChannel (5.1.d)

**Objective:** bundle physical links for bandwidth and resiliency, on both LAN and SAN sides.

## 9.1 Task 8.1 — Ethernet Port Channel (vPC) on the LAN Side

If N5K-1/N5K-2 form a vPC domain toward each FI, building a working vPC needs four pieces in order — feature enablement, the peer-keepalive link, the peer-link itself, and the downstream FI-facing port channel. Skipping the peer-link (the piece most often left out) leaves vPC unable to synchronize state between N5K-1 and N5K-2 at all, even if the peer-keepalive and the FI-facing port channel both look fine individually.

**1 — Enable features (both N5K-1 and N5K-2):**

??? "Commands"
    ```text
    feature vpc
    feature lacp
    ```

**2 — vPC domain and peer-keepalive.** The peer-keepalive is a routed, out-of-band heartbeat — it must already be up before the peer-link can form, and it needs its own source/destination pair, separate from the peer-link's own data path (commonly the mgmt0 VRF, as below):

??? "Commands"
    ```text
    ! On both N5K-1 and N5K-2
    vpc domain 1
      peer-keepalive destination <peer-mgmt-ip> source <this-switch-mgmt-ip> vrf management
    ```

**Verify the keepalive is actually up before moving on** — a vPC domain with a down or misconfigured peer-keepalive will not bring vPCs into a working state no matter how correct the peer-link and downstream port channels are:

??? "Commands"
    ```text
    show vpc peer-keepalive
    ```

**3 — Peer-link (N5K-1 ↔ N5K-2 physical links).** This is the piece a stubbed-down vPC build most often skips — the peer-link is what actually synchronizes MAC/VLAN/STP state between the two switches, and it must be a Layer-2 trunk with `spanning-tree port type network` (this enables Bridge Assurance specifically on the peer-link, which is Cisco's documented best practice for detecting a unidirectional peer-link failure) and the `vpc peer-link` role:[^peerlink]

??? "Commands"
    ```text
    ! On both N5K-1 and N5K-2 — physical members between the two switches
    interface Ethernet1/3-4
      channel-group 100 mode active

    interface port-channel100
      switchport
      switchport mode trunk
      switchport trunk allowed vlan 10,11
      spanning-tree port type network
      vpc peer-link
    ```

Restrict the peer-link's allowed-VLAN list to the VLANs actually carried over vPC (10, 11 in this lab) — Cisco's own vPC best-practice guidance is to prune the peer-link to only the VLANs it needs to carry, rather than trunking everything by default.

**4 — FI-facing (downstream) vPC.** This is the port channel that was already in this module before the correction — kept as-is, just now built on top of an actual peer-link instead of standing alone:

??? "Commands"
    ```text
    ! On both N5K-1 and N5K-2
    interface port-channel10
      switchport
      switchport mode trunk
      switchport trunk allowed vlan 10,11
      vpc 10

    interface Ethernet1/1
      channel-group 10 mode active
    ```

On the FI side, bundle the corresponding uplink ports into a **Port Channel** under **LAN > LAN Cloud > Fabric A > Port Channels**.

**Verify the whole vPC domain, not just the downstream port channel:**

??? "Commands"
    ```text
    show vpc
    show vpc brief
    show port-channel summary
    show interface port-channel100
    show interface port-channel10
    ```

Confirm: peer adjacency is **peer-ok**, peer-keepalive is **alive**, the peer-link (`port-channel100`) is **up**, **vPC role** is consistent (primary/secondary), **consistency-parameters** show **success** (a mismatch here — e.g. differing MTU or trunk-allowed-VLAN lists between the two switches — is what most often blocks a vPC from coming fully up even though the peer-link itself is up), and VLAN 10/11 both show active across the FI-facing port channel.

!!! warning "What a missing or inconsistent peer-link looks like"
    Without a working peer-link, `show vpc` reports the peer-link as down and the vPC domain falls back to individual, non-synchronized forwarding on each switch — downstream port channels toward the FI may still individually pass traffic, but MAC/ARP state isn't synchronized between N5K-1 and N5K-2, which shows up as intermittent duplicate-MAC or flapping symptoms rather than a clean outage. A consistency-parameter mismatch (e.g. mismatched `switchport trunk allowed vlan` lists between the two peer-link ends) similarly leaves vPC role negotiation stuck rather than fully operational — `show vpc consistency-parameters global` isolates exactly which parameter disagrees.

[^peerlink]: [Cisco Nexus Series vPC Best Practices Design Guide](https://www.cisco.com/c/dam/en/us/td/docs/switches/datacenter/sw/design/vpc_design/vpc_best_practices_design_guide.pdf) and [Cisco Nexus 5000 Series NX-OS Layer 2 Switching Configuration Guide](https://www.cisco.com/c/en/us/td/docs/switches/datacenter/nexus5000/sw/configuration/guide/cli/CLIConfigurationGuide.html) — `spanning-tree port type network` on the peer-link enables Bridge Assurance specifically on that link, and is Cisco's documented best practice for peer-link construction.

## 9.2 Task 8.2 — FC Port Channel (SAN Side)

If more than one FC/FCoE link exists between an FI and its N5K, bundle them into a **SAN Port Channel**. This is specifically an **F-port-channel** — the FI (acting as an NP/NPV-style device toward the core, per Module 6) forms F ports toward the N5K core switch, and the N5K side channels them together. Cisco's Nexus 5000 SAN Switching documentation is explicit that F-port-channels only support **Active-Active mode — `ON` mode is not supported.**[^fpc] Skipping the mode keyword (or leaving it at the platform default of `on`) is a real, common misconfiguration, not a cosmetic omission.

**Prerequisites, in order:**

1. `feature npiv` — already enabled on N5K-3/N5K-4 as this pod's confirmed baseline (Section 1.1); not reconfigured here, but it must already be live, since NPIV is what lets multiple vHBA FLOGIs ride the same physical/bundled F port.
2. `feature fport-channel-trunk` — required specifically because this port channel needs to trunk more than one VSAN (100 and 101). Enable it before creating the SAN port channel, not after.

**Build the SAN port channel with explicit Active mode:**

??? "Commands"
    ```text
    ! N5K-3 (Fabric A core) — global config
    feature fport-channel-trunk

    ! Create the SAN port channel and set it to Active mode
    interface san-port-channel 1
      channel mode active
      switchport mode F
      switchport trunk mode on
      switchport trunk allowed vsan 100,101

    ! Add the member FC interfaces to the same channel
    interface fc1/1-2
      channel-group 1 force
      no shutdown
    ```

Carry both of Fabric A's VSANs (100, 101) on the port channel, same as the single F port in Module 2, Task 2.3 — bundling members doesn't change which VSANs the fabric needs. Mirror this on N5K-4 for Fabric B (VSAN 200, 201).

On the FI: **SAN > SAN Cloud > Fabric A > FC Port Channels**, add the member uplinks. The FI side of an F-port-channel toward an NPV-mode FI negotiates Active mode automatically once the N5K side is configured correctly — there's no separate FI-side mode keyword to set, but a mismatch here is exactly what produces a member stuck in individual/down state in Task 8.3's verify step.

!!! note
    `channel-group <id> force` on the FC member interfaces is the correct way to add an interface to a SAN port channel outside the auto-created default — it does not itself set the channel mode. The mode is set once, on the `san-port-channel` interface itself, via `channel mode active`.

## 9.3 Task 8.3 — Verify

Proving the SAN port channel is actually operating correctly — not merely configured — needs more than a summary glance:

??? "Commands"
    ```text
    show port-channel summary
    show interface port-channel10
    show san-port-channel summary
    show interface san-port-channel 1
    show flogi database
    show npv status
    ```

Confirm all members show `(P)` (up, in port channel) — a member stuck in `(I)` (individual) or `(D)` (down) means a parameter mismatch (speed, mode, or allowed VSAN/VLAN list) between the two ends; for the SAN port channel specifically, a member stuck individual is the single most common symptom of a channel-mode mismatch (one end Active, the other still defaulted to `on`) rather than a cabling or VSAN problem. `show flogi database` should still show one FLOGI per vHBA on that fabric, now riding the bundled port channel instead of a single physical F port — bundling members must not change who's logged in, only how many physical links carry that traffic. `show npv status` confirms the FI-facing side's NPV/uplink state where run from the FI's NX-OS CLI context.

!!! question "Check yourself"
    A SAN port channel member sits in `(I)` individual state even though the physical link is up and the allowed-VSAN list matches on both ends. What's the one setting you haven't checked yet that's specific to F-port-channels and doesn't have an equivalent concern on the Ethernet port-channel side?

[^fpc]: [Cisco Nexus 5000 Series NX-OS SAN Switching Configuration Guide, Release 5.1(3)N1(1) — Configuring SAN Port Channels](https://www.cisco.com/c/en/us/td/docs/switches/datacenter/nexus5000/sw/san_switching/513_n1_1/b_Cisco_n5k_nxos_sanswitching_config_guide_rel513_n1_1/b_Cisco_n5k_nxos_sanswitching_config_guide_rel513_n1_1_chapter_01000.html): only Active-Active mode is supported for F-port-channels; ON mode is not supported. `feature fport-channel-trunk` must be enabled before configuring an F port channel that trunks more than one VSAN.
