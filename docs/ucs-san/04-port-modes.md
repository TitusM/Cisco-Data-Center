# 4. Module 3 — Port Modes (4.2.c)

**Objective:** know every personality a physical port can take on both the FI and the Nexus 5000, and how to change it.

## 4.1 Task 3.1 — FI Port Roles

Walk **Equipment > Fabric Interconnects > Fixed/Expansion Module** and identify each role you can assign:

| Role | Used for |
|---|---|
| Server Port | Downlink to chassis IOM or direct-connect rack server |
| Uplink Port (Ethernet) | LAN uplink to N5K-1/N5K-2 |
| FC Uplink Port | Native FC uplink to N5K-3/N5K-4 |
| FCoE Uplink Port | Converged Ethernet uplink carrying FCoE to the core |
| FCoE Storage Port | Direct FCoE-attached storage (not used in this topology, but know it exists) |
| Appliance Port | Direct-attached Ethernet appliance (e.g. NFS filer) |
| Monitor (SPAN) Port | Local traffic capture |

Practice converting an unused port between two of these roles and note which changes require no traffic disruption versus which require the port to be re-acknowledged.

## 4.2 Task 3.2 — Unified/Flex Port Conversion

If your FI or N5K-3/N5K-4 use unified/flex ports (e.g. 6248UP, 5548UP/5596UP), convert a contiguous block from Ethernet to FC personality:

- **FI:** Equipment > Fixed Module (or Expansion Module) > **Configure Unified Ports**. The reboot scope depends on which module you change: a change on the **fixed module reboots the entire Fabric Interconnect** — roughly an 8-minute outage for all data traffic through that FI — while a change on an **expansion module only reboots that module**, about a 1-minute interruption limited to its own ports. Plan a maintenance window sized for the fixed-module case if that's what you're touching.
- **N5K:**

```text
slot 1 port 1-4 type fc
```

then `copy running-config startup-config` and reload the module. Confirm with:

```text
show port-resource module 1
show interface brief
```

!!! question "Check yourself"
    Why do unified port conversions require a reload, while simply changing an existing FC port from F to E mode does not? And why is converting a few ports on an FI's fixed module a bigger deal, operationally, than the same conversion on an expansion module?
