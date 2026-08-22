# Appendix A — Command Quick Reference

## A.1 NX-OS — SAN (N5K-3 / N5K-4)

??? "Commands"
    ```text
    ! feature npiv        — pod baseline, already enabled; confirm with `show feature | include npiv` (Section 1.1), don't reconfigure
    feature fcoe
    vsan database
      vsan 100
      vsan 101
    interface fc1/1
      switchport mode F
      switchport trunk allowed vsan 100,101
    device-alias database
      device-alias name <name> pwwn <wwpn>
    device-alias commit
    zone name <zone> vsan 100
      member device-alias <name>
    zoneset name <zoneset> vsan 100
      member <zone>
    zoneset activate name <zoneset> vsan 100
    show flogi database
    show fcns database vsan 100
    show fcns database vsan 101
    show zoneset active vsan 100
    show zoneset active vsan 101
    show feature | include npiv
    show vsan
    ```

(N5K-4 mirrors this with VSAN 200/201 for Fabric B.)

## A.2 NX-OS — LAN (N5K-1 / N5K-2)

??? "Commands"
    ```text
    feature vpc
    vpc domain 1
      peer-keepalive destination <ip> source <ip> vrf management
    interface port-channel1
      switchport mode trunk
      switchport trunk allowed vlan 10,11,1000
      vpc 1
    interface Ethernet1/1
      channel-group 1 mode active
    show port-channel summary
    show interface trunk
    show vpc brief
    ```

(The Fabric B-facing interface carries the same shared VLAN 10,11 pair, plus its own FCoE VLAN 2000 in place of Fabric A's 1000 — the LAN VLANs are common to both fabric uplinks; only the FCoE VLAN tied to each fabric's VSANs differs.)

## A.3 UCS Manager (GUI paths)

??? "Commands"
    ```text
    Equipment > Fabric Interconnects > Fixed Module > [Ethernet | FC] Ports   (port roles)
    Equipment > Configure Unified Ports                                       (personality conversion)
    LAN > LAN Cloud > Fabric A/B > Port Channels                              (Ethernet uplink bundling)
    SAN > SAN Cloud > Fabric A/B > VSANs | FC Port Channels                   (SAN uplink + trunking)
    SAN > SAN Cloud > Fabric A/B > Set FC Switching Mode                      (End Host vs Switch Mode)
    Servers > Pools | Policies | Service Profile Templates                    (Module 1 constructs)
    ```

---

# Appendix B — Pre-Flight Summary Card

| Check | Command / Location |
|---|---|
| FLOGI present | `show flogi database` |
| FCNS entries | `show fcns database vsan <id>` |
| Active zoneset | `show zoneset active vsan <id>` |
| NPIV feature enabled (core) | `show feature \| include npiv` |
| NPV status (FI, via `connect nxos a` or `connect nxos b`) | `show npv status` / `show npv flogi-table` |
| Port channel state | `show port-channel summary` / `show san-port-channel summary` |
| VLAN/VSAN trunk allowed list | `show interface trunk` / `show vsan` |
| Service profile association | UCSM: Servers > Service Profiles, Assoc State column |
