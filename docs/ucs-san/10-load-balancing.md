# 10. Module 9 — Load Balancing (5.1.e)

**Objective:** confirm traffic is actually spread across bundled links and across fabrics, not just theoretically capable of it.

## 10.1 Task 9.1 — Ethernet Port-Channel Hashing

??? "Commands"
    ```text
    port-channel load-balance ethernet source-dest-port
    show port-channel load-balance
    ```

(This is Nexus 5000 syntax — the `ethernet <keyword>` form. Nexus 7000/9000 platforms use a different keyword style, e.g. `src-dst ip-l4port`; don't mix the two.)

Pick a hash that includes L4 port when traffic is mostly IP flows between the same host pairs, so a small number of conversations don't all land on one member link.

## 10.2 Task 9.2 — FC Port-Channel Load Balancing

FC port channels load-balance per-exchange by default (OX_ID-based), which is almost always correct; per-flogi is available for edge cases where in-order delivery across the whole channel matters more than distribution. Check current mode:

??? "Commands"
    ```text
    show san-port-channel summary
    ```

## 10.3 Task 9.3 — Default Dynamic Pinning vs. vNIC Fabric Failover

Two distinct mechanisms, don't conflate them:

- **Default UCS dynamic pinning:** without any pin group configured, UCS Manager dynamically selects an appropriate uplink Ethernet port or port channel for each vNIC on its own. This selection is not permanent — it can change following events such as an uplink interface flap or a server reboot, since UCSM re-evaluates the assignment rather than remembering a specific prior choice.
- **vNIC Fabric Failover** (a per-vNIC checkbox in the service profile): if the *primary* fabric's uplink fails, the vNIC's MAC moves to the other fabric's FI. This is a failover mechanism, not load balancing — only one fabric carries that vNIC's traffic at a time.

Neither of these requires you to configure anything — they're the platform default behavior. Task 9.4 below is what you configure when default dynamic pinning isn't precise enough for your needs.

## 10.4 Task 9.4 — LAN and SAN Pin Groups

**Objective:** understand when explicit pinning is worth the loss of UCSM's automatic uplink selection, and be able to prove where a vNIC's or vHBA's traffic actually lands once pinned.

Manual pinning is **not** automatically a best practice — default dynamic pinning (10.3) already spreads load reasonably and re-adapts on its own after a link flap. Pin Groups trade that adaptability for determinism: useful when you need a specific vNIC or vHBA to land on a specific uplink for troubleshooting, capacity planning, or a change-control requirement that says "this traffic uses this exact path" — not because pinning is inherently superior to letting UCSM choose.

**LAN Pin Groups** (**LAN > Policies > Pin Groups**) explicitly pin a server vNIC's Ethernet traffic to a selected uplink Ethernet port or Ethernet port channel. A LAN Pin Group isn't applied directly to a vNIC in isolation — it's consumed through the vNIC's own policy, template, or the service profile that references that vNIC.[^lanpin]

**SAN Pin Groups** (**SAN > Policies > Pin Groups**) do the same for a vHBA's Fibre Channel traffic, pinning it to a selected FC uplink. Cisco's own documentation calls out one caveat worth knowing before you build one: **SAN Pin Groups have no effect when the Fabric Interconnect's FC switching mode is Switch Mode** — they're only relevant in **End Host Mode**, which is exactly the NPV-like mode this lab's FIs use (`05-fc-fcoe.md` §5.1). So for this lab's actual architecture, SAN Pin Groups are a real, usable tool, not a moot one.[^sanpin]

**Build one (LAN side, as a worked example):**

1. **LAN > Policies > Pin Groups > Create LAN Pin Group**, name it, and select the target uplink Ethernet port or port channel (e.g. the FI-A-facing uplink from Task 2.1).
2. Reference that Pin Group from the relevant vNIC template or service profile's vNIC definition.

**Verify the pin actually took effect** — don't assume it from the policy alone:

??? "Commands"
    ```text
    show interface port-channel1 counters
    show interface counters trunk
    ```

Confirm the pinned vNIC's traffic actually lands on the uplink you selected, not just that the policy saved without error — a Pin Group that silently fails to apply (wrong org scope, vNIC not actually referencing it) looks identical to a working one until you check the counters.

!!! question "Check yourself"
    If you rely on default dynamic pinning instead of a LAN Pin Group, and the uplink a vNIC happened to land on flaps, what happens to that vNIC's traffic — does it stay pinned to a now-down uplink, or move? Now answer the same question for a vNIC that *is* explicitly pinned via a LAN Pin Group whose target uplink goes down. What's the actual trade-off you're making by pinning?

[^lanpin]: [Cisco UCS Manager Network Management Guide Using the CLI, Release 6.0 — LAN Pin Groups](https://www.cisco.com/c/en/us/td/docs/unified_computing/ucs/ucs-manager/CLI-User-Guides/Network-Mgmt/4-2/b_cli_ucsm_network_management_guide_4_2/b_CLI_UCSM_Network_Management_Guide_chapter_01010.html)
[^sanpin]: Cisco UCS Manager Storage Management Guide, Release 6.0 — SAN Pin Groups: SAN Pin Groups are not relevant when the Fabric Interconnect is in Fibre Channel switch mode.

!!! question "Check yourself"
    If a blade has only one vNIC per fabric, does enabling more uplink ports in that fabric's port channel increase that vNIC's individual throughput? Why or why not — and what would you add to actually increase it?
