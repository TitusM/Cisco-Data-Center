# 1. Pre-Lab Checklist and Day-0 Bring-Up

**This guide assumes every device is factory-default or freshly erased** — no VLANs beyond the default VLAN 1, no VSANs beyond the default VSAN 1, no zoning, no pools, no policies, no service profiles, and every physical port sitting in an unconfigured role. Every module below builds from that empty state; nothing is assumed to already exist unless a previous task in this guide created it. If a device in your pod is *not* actually blank, `write erase` (NX-OS) / **Erase Configuration** (UCSM install wizard) it back to factory default before you start, so your results match what each module expects to see.

## 1.1 N5K-1, N5K-2, N5K-3, N5K-4 — Initial Setup

On a factory-default Nexus 5000, the boot process drops you into the interactive initial setup dialog. Run it (or confirm it was already completed) on all four switches:

- Set the hostname (`N5K-1` … `N5K-4`), admin password, and `mgmt0` IP/mask/gateway.
- Enable SSH; decline unnecessary services you don't need for the lab.
- Accept the defaults for everything else, then `copy running-config startup-config`.

Confirm the result is genuinely blank before moving on — with one exception. This pod's baseline has **NPIV already enabled on N5K-3/N5K-4** before you touch anything, so don't expect (or write-erase away) a truly feature-less state on those two switches:

??? "Commands"
    ```text
    show vlan brief        ! should show only VLAN 1
    show vsan               ! should show only VSAN 1 (SAN switches only)
    show feature | include enabled   ! N5K-1/N5K-2: nothing beyond platform defaults — vpc, fcoe off
                                      ! N5K-3/N5K-4: npiv already enabled (pod baseline) — everything else off
    show running-config | include feature
    ```

!!! warning "N5K-3, N5K-4 — confirm, don't configure, NPIV"
    Because this pod ships with `feature npiv` already turned on for the SAN switches, this is a verification step, not a build step — toggling a feature that's already live risks bouncing existing FLOGIs for no reason. Confirm it's on before you rely on it anywhere downstream (Module 2's F-port trunk needs it already enabled the moment that trunk comes up, and Module 6 verifies it in depth):

??? "Commands"
    ```text
    ! N5K-3, N5K-4 — confirm only
    show feature | include npiv     ! expect: npiv    1        enabled
    show running-config | include npiv
    ```

If it comes back **disabled** on either switch — pod baseline wasn't applied, or someone reset it — enable it now rather than waiting for Module 2 to surface the failure indirectly:

??? "Commands"
    ```text
    ! N5K-3, N5K-4 — fallback only, if the confirm step above showed npiv disabled
    feature npiv
    ```

**Enable the remaining base features each switch will need**, since none of them are on by default and later modules assume they already are:

??? "Commands"
    ```text
    ! N5K-3, N5K-4 (SAN switches)
    feature fcoe          ! only if this pod uses FCoE rather than native FC uplinks

    ! N5K-1, N5K-2 (LAN switches)
    feature vpc            ! only if you're building vPC to the FIs (Module 8)
    ```

## 1.2 FI-A, FI-B — Cluster Setup

A factory-default Fabric Interconnect also boots into an interactive setup wizard. The two FIs must be set up in a specific order because the second one joins the first's cluster rather than forming its own:

1. **FI-A first, as a new cluster:** choose "Create a new cluster," set the cluster (virtual) IP, FI-A's own mgmt IP, admin password, and system name.
2. **FI-B second, joining the cluster:** FI-B's setup wizard detects FI-A over the L1/L2 cluster links and offers "Add this Fabric Interconnect to the cluster." Accept it, set FI-B's own mgmt IP, and let it sync.
3. **Launch UCSM** via the cluster VIP and confirm both FIs appear under **Equipment > Fabric Interconnects**, cluster state HA-ready, before doing anything else.

**Verify the cluster from the NX-OS-style CLI.** Connect to the cluster VIP (SSH or console) and confirm both FIs are up and which one is primary:

??? "Commands"
    ```text
    FI-A# show cluster state
    Cluster Id: 0x4432f72a371511de-0xb97c000de1b1ada4

    A: UP, PRIMARY
    B: UP, SUBORDINATE

    HA READY
    ```

The commands `show fabric-interconnect {a | b} detail` and `show system detail` display the IP addresses for the management interfaces and the virtual IP address, respectively, of the cluster:

??? "Commands"
    ```text
    FI-A# show fabric-interconnect a detail
    Fabric Interconnect:
        ID: A
        OOB IP Addr: 10.10.10.11
        OOB Gateway: 10.10.10.1
        OOB Netmask: 255.255.255.0
        ...

    FI-A# show system detail
    System:
        Name: Nexus-DC-1-UCS
        Virtual IP Addr: 10.10.10.10
        ...
    ```

!!! danger "HA NOT READY"
    If `show cluster state` reports **HA NOT READY**, stop here and check the L1/L2 cluster links between the two FIs before proceeding — a healthy L1/L2 connection is a prerequisite for everything that follows in Module 1.

## 1.3 Confirm the Blank Slate in UCSM

Before Module 1, walk these screens once and confirm they're empty — if any of them already has content, this pod isn't actually fresh and your mileage on later steps will vary:

- **Equipment > Chassis** — empty. No chassis discovered yet is expected and correct; nothing discovers until Module 1, Task 1.0 sets the discovery policy and the chassis-facing ports are configured as Server Ports.
- **Equipment > [Fixed Module] > Ethernet/FC Ports** — every physical port shows role **Unconfigured**.
- **LAN > LAN Cloud > VLANs** — only the default VLAN 1.
- **SAN > SAN Cloud > VSANs** — only the default VSAN 1.
- **Servers > Pools / Policies / Service Profile Templates / Service Profiles** — all empty.

## 1.4 Other Pre-Flight Checks

1. Confirm console/SSH access to N5K-1, N5K-2, N5K-3, N5K-4, and UCSM (both FI VIPs and the cluster VIP).
2. Record NX-OS and UCSM firmware versions (`show version` / Equipment > Firmware). Unified-port conversions and FCoE behavior vary by release.
3. Confirm which physical ports are unified/flex ports (capable of Ethernet or FC personality) on N5K-3/N5K-4 and on the FIs — this determines what Module 3 can actually demonstrate on your hardware.
4. Record the physical cabling you actually have, using this table as a starting template:

| Link | From | To | Type | Purpose |
|---|---|---|---|---|
| 1 | Storage | N5K-3 | FC | SAN-A target path |
| 2 | Storage | N5K-4 | FC | SAN-B target path |
| 3 | N5K-3 | FI-A | FC or FCoE | SAN-A uplink |
| 4 | N5K-4 | FI-B | FC or FCoE | SAN-B uplink |
| 5 | FI-A | UCS-B IOM-A | FCoE (converged) | Chassis uplink, Fabric A |
| 6 | FI-B | UCS-B IOM-B | FCoE (converged) | Chassis uplink, Fabric B |
| 7 | FI-A | N5K-1 / N5K-2 | Ethernet | LAN uplink, Fabric A |
| 8 | FI-B | N5K-1 / N5K-2 | Ethernet | LAN uplink, Fabric B |
| 9 | Host | N5K-1 | Ethernet | Rack server LAN, path 1 |
| 10 | Host | N5K-2 | Ethernet | Rack server LAN, path 2 |
