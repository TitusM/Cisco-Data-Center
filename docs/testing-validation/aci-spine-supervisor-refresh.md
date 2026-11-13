# The Art of Testing and Validation: De-risking an ACI Spine Supervisor Refresh

*An engineering case study: replacing N9K-SUP-A with N9K-SUP-A+ before an ACI software upgrade*

!!! info "About this case study"
    This article describes a validation methodology developed around a real supervisor-refresh exercise. The customer topology is generalized; test cases and acceptance criteria are **proposed validation requirements**, not claims that every test has passed. The EOBC access-violation output below is an observed troubleshooting example. Use the hardware guide for the exact chassis and software release, and obtain Cisco TAC review where a recovery path is unclear.

## Why I chose this exercise

I am currently leading a validation cycle for replacing older **N9K-SUP-A** supervisor modules with **N9K-SUP-A+** modules in Cisco ACI modular spine switches. The refresh is a prerequisite to a later software upgrade: Cisco's ACI-mode switch release notes list the N9K-SUP-A among hardware no longer supported in newer releases.

The physical task sounds manageable. Cisco publishes the replacement procedure, and the outgoing supervisors are already running the required **current** ACI software. The uncertainties sit with the incoming modules and with the behavior of the whole fabric while we carry out the change.

An incoming SUP-A+ can reach us with NX-OS in bootflash, an older ACI image, or no usable local ACI image. USB recovery may be prohibited. And in a fabric with only two spines, taking one spine out for maintenance leaves the other responsible for the fabric's remaining spine connectivity.

That combination turns a hardware replacement into a useful example of how I approach validation: **start with the customer's operating constraints, identify what could fail, reproduce those conditions, measure the impact, and provide evidence that the change can be executed and recovered safely.**

## 1. Define the exact change and the boundaries of the test

| Dimension | What to establish before testing |
| --- | --- |
| Starting state | Two-spine ACI fabric; existing SUP-A modules run the correct *current* ACI release |
| Intended end state | Both spines on SUP-A+; stable fabric on the current release, ready for a *separate* software-upgrade qualification |
| Replacement variables | SUP-A+ part number, serial, BIOS, installed image type/version, boot variables, bootflash health |
| Platform dependencies | Exact 9504/9508/9516 chassis, line cards, fabric modules, system controllers, supervisor slot occupancy |
| Operational constraints | No USB recovery; possible absence of pre-staging; permitted management/console access; maintenance window |
| Business constraints | Traffic criticality, allowable transient disruption, expected peak load, supported application flows |
| Out of scope | Claiming that supervisor replacement alone proves the subsequent ACI software upgrade is safe |

**First lesson:** document the software precisely. ACI APIC releases and ACI-mode switch firmware have related but different version identifiers. Record the actual version strings from both APIC and the spine rather than assuming an APIC version is the filename or switch version.

Cisco's [16.1(5) ACI-mode release notes](https://www.cisco.com/c/en/us/td/docs/dcn/aci/apic/6x/release-notes/cisco-aci-nx-os-release-notes-1615.html) list SUP-A/SUP-B and several legacy fabric modules and line cards as unsupported, and warn about attempting to upgrade unsupported hardware. A successful SUP-A+ swap does **not** clear the whole chassis for the later upgrade. Audit every installed component against the **specific intended target release**, not just the supervisors.

### Assumptions to challenge

1. **"The existing supervisor runs the correct image."** Yes: the running version is known. But confirm that a *matching image file* is present, readable, and available through the recovery mechanism. A running software version does not prove that the EOBC-serving path or its permissions work.
2. **"A supervisor swap can be treated as a hitless switchover."** Not on these ACI modular spines. Cisco documents a **stateless** supervisor switchover and says hardware replacement must be performed after **spine decommissioning**; GIR is not supported for this operation.
3. **"One remaining spine is enough."** It might be enough for the expected load, but that is an engineering hypothesis to measure, not a conclusion from the topology diagram.
4. **"Mixed generations are supported."** Distinguish **SUP-A in one chassis and SUP-A+ in another chassis** from different active/standby types **inside one chassis**. Cisco's guide requires matching types for a normal dual-supervisor configuration, while separately documenting the A-to-A+ upgrade transition. Follow a chassis-specific, reviewed sequence rather than leaving an undocumented mixed pair operating.

## 2. Design the lab around the risks

A useful lab must reproduce the **failure domains**, not merely the part numbers:

```text
                 APIC cluster / management / time sync
                               |
                  [ACI fabric under test]
                         /          \
                 Spine-1              Spine-2
                 SUP-A -> A+          SUP-A
                    | \              / |
                    |  \            /  |
                 Leaf-A  Leaf-B  Leaf-C  Leaf-D
                   |       |       |       |
                EP-A     EP-B    Border   EP-D
                                   |
                            External router
```

**Minimum topology:** two independently usable spines, at least two leafs with test endpoints on different leafs, and a means to monitor inter-leaf traffic continuously. Add a border leaf/L3Out, route-reflector role, multicast and Multi-Pod/IPN dependencies **if they exist in production**. A lone test endpoint on the same leaf will not exercise the spine forwarding path.

**Reproduce production differences:** fabric-node IDs, port speeds and bundle sizes, supervisor slot occupancy, fan/fabric-module generation, image family, APIC policy and relevant route-reflector placement. When exact production scale is unavailable, document the gap and use targeted stress tests rather than claiming equivalent scale.

**Keep destructive failures in the lab.** Broken images, permissions, forced loader states and intentionally failed recovery must not be introduced into a live production fabric.

## 3. Build a validation contract before touching hardware

The customer and validation team should agree on what **success** means. Avoid declaring that "traffic looked fine" after maintenance.

| Service indicator | How to collect it | Example pass rule — customer must approve |
| --- | --- | --- |
| End-to-end availability | Continuous test flows across distinct leafs | No sustained unexplained outage; transient loss stays within agreed budget |
| Loss and convergence | Traffic generator per-stream loss and timestamps | Measured maximum interruption is below agreed threshold |
| Throughput and congestion | Offered/received rate, spine/leaf port utilization, discards | No congestion-related degradation at the tested peak load |
| Latency/jitter | Per-stream latency distribution at fixed offered load | Within pre-agreed baseline deviation/SLO |
| Fabric control plane | IS-IS peers, COOP state, relevant MP-BGP peers/routes | Expected peers/state converge and remain stable |
| Endpoint/policy correctness | Endpoint learning/moves, EPG contract allow/deny probes | Expected reachability and policy behavior unchanged |
| Chassis health | Module inventory, online diagnostics, power/thermal and active faults | No new unresolved critical hardware/fabric faults |
| Recovery capability | Complete console trace; boot path, image and reboot persistence | Approved recovery works without USB and survives an additional reboot |
| Procedural reliability | Timed execution, decision points and rollback rehearsal | Steps reproducible inside approved maintenance and rollback budgets |

Those thresholds are deliberately not invented here. They must come from the customer's application requirements and measured baseline. Recording **zero** loss on a single low-rate ping stream is not a substitute for an agreed traffic SLO.

### Instrument the change, don't just observe it

Use a traffic generator (Ixia/Spirent where available) or sufficiently capable hosts, together with scripted snapshots of the fabric.

Traffic coverage should include:

- **Inter-leaf east–west traffic**, both same-EPG and permitted inter-EPG flows; include denied contract cases to detect accidental over-permissiveness.
- **North–south traffic** via representative L3Out routing, where used.
- **Different flow sizes and hashing diversity**: many short flows, long-lived flows, and a mix of packet sizes.
- **Unicast, multicast/BUM, endpoint mobility, and route changes** where relevant to the customer's design.
- **Steady load and bursts** during decommission, one-spine operation and recommission.

Log generator counters continuously with timestamps. Collect ACI and hardware state at defined checkpoints, and correlate events to the traffic record. Keep time sources aligned; otherwise even a successful test produces weak convergence evidence.

## 4. Follow staged gates, with no automatic progression

### Gate 0 — Compatibility and readiness

Inventory **every** installed supervisor, line card, fabric module, system controller and relevant transceiver. Match the target release support matrix. Verify spare SUP-A+ identifiers, hardware health, BIOS requirements, accessible console/OOB, available replacement parts, safe physical handling and a TAC escalation route.

Record whether each replacement unit is **pre-staged, uninspected, NX-OS-only, older-ACI, or image-less**. If pre-staging is impossible, the MoP needs a tested "unknown incoming image" branch.

**Stop if:** unsupported hardware remains in the proposed upgrade bill of materials; the no-USB recovery strategy is unproven; or the single-spine traffic/capacity test has not been accepted.

### Gate 1 — Healthy dual-spine baseline

Before maintenance, capture:

- APIC fabric membership, fabric/tenant faults, health and historical baseline.
- Node IDs, hardware/PID/serial/slots, `show version`, `show module`, `show environment`, `show diagnostic result module all`, and `show discoveryissues` where applicable.
- IS-IS adjacency, endpoint/COOP information, MP-BGP route-reflector state **if configured**, and relevant route/next-hop information.
- Fabric uplink rates, counters, interface discards/errors, traffic-generator flow statistics, and control-plane event timestamps.

Cisco's [ACI switch baseline-health guide](https://www.cisco.com/c/en/us/support/docs/cloud-systems-management/application-policy-infrastructure-controller-apic/225960-troubleshoot-aci-switch-baseline-health.html) documents the hardware and baseline commands above. Use release-specific CLI/API methods for deeper COOP/IS-IS/BGP checks.

**Stop if:** baseline fabric health is already degraded and the deviations are not understood.

### Gate 2 — Remove one spine while traffic is running

Run representative traffic **before** starting the APIC decommission workflow. Follow the applicable Cisco guide, including its documented IS-IS redistribution metric prerequisite and fabric-membership procedure.

Record three separate conditions:

1. **Transition:** precise loss/reconvergence window as the target spine leaves service.
2. **Reduced-redundancy steady state:** the surviving spine carries the agreed load for a meaningful observation period, with headroom and no unexplained errors.
3. **Stress/failure sensitivity:** what happens with production-relevant peak/burst flows? Do not deliberately fail the only remaining spine in production.

Do not assume removing one of two spines literally halves throughput. Hash distribution, link capacities and offered traffic determine what moves and where congestion appears. Distinguish a fabric-wide failure from a workload whose endpoints are both local to the same leaf.

**Stop if:** sustained loss exceeds the accepted budget, the surviving spine exhausts headroom, critical adjacencies are missing, or APIC faults indicate unsafe continued operation.

### Gate 3 — Supervisor exchange and image recovery

With the target spine decommissioned, validate the Cisco-recommended physical sequence for **the exact chassis** and examine the incoming SUP-A+ behavior. Record each boot branch:

| Incoming SUP-A+ condition | What to test | Evidence required |
| --- | --- | --- |
| Matching ACI image in bootflash | Local boot and correct version/role | Boot log, image identity, module state |
| NX-OS image only | Recovery into ACI mode without USB | Verified recovery method and correct final image |
| Older/different ACI image | No unintended version mismatch; use approved target/current-image path | Version evidence before and after |
| Empty/unusable local image | EOBC or other Cisco-supported recovery | Console transcript and transfer outcome |
| Stuck at loader | Applicable documented force-download branch, with TAC approval | Command path, outcome and reboot test |
| Older BIOS preventing boot | Supported firmware recovery branch feasible without USB | BIOS record and an approved, tested plan |
| EOBC transfer error | Isolate server/path/permission/image-serving cause | Failure signature, confirmed root cause and retest |

Cisco's [N9508 ACI hardware procedure](https://www.cisco.com/c/en/us/td/docs/switches/datacenter/nexus9000/hw/aci_9508_hig/guide/b_n9508_aci-mode_hardware_install_guide/m_install_n95xx_modules_aci.html) documents local image boot, `eobc`, copying an image after the supervisor boots, setting boot variables, and a separate `reload module <x> force-dnld` recovery branch. It also documents a BIOS-version consideration. The individual branches must be checked against the platform and release in use.

!!! warning "Do not improvise privileged recovery commands"
    The guide's post-boot `chmod 666` instruction on the newly booted supervisor is **not proof** that changing permissions on the active supervisor will resolve a pre-boot EOBC failure. Verify the actual serving path, filesystem view, ownership/permissions and supported commands with Cisco TAC before changing privileged files. Treat a persistent EOBC access violation as a **failed recovery test**, not a reason for undocumented trial-and-error in production.

### A real example: EOBC access violation

An incoming supervisor reached the bootloader and attempted EOBC recovery:

```text
loader > eobc
network is ready.
Filename: /img-sync/curr-ks.img
Address: 127.1.1.28
Server: 127.1.1.27
Filesystem type is tftp, using whole disk
TFTP error 2 (Access violation)
Error 15: File not found
loader >
```

The internal network path came up and the loader requested `/img-sync/curr-ks.img`, but the transfer was rejected. The TFTP **access violation** is an observed symptom; the trailing generic "file not found" error is **not** evidence on its own that the running ACI image was absent.

A disciplined investigation would capture the precise requested path, test whether the service can expose it, inspect relevant file ownership/permissions where supported, check logs from the internal image-serving side if available, and rerun the supported path after the cause has been confirmed. Record the **cause** and the **fix** separately.

Here is the practical customer question: **If a replacement arrives at the site with only NX-OS and USB is prohibited, can the maintenance team recover it reliably without exceeding the approved window?**

If the answer is not yet backed by a successful test, the MoP needs a prerequisite or alternate plan.

### Gate 4 — Recommission and validate mixed-generation fabric

After the first spine has SUP-A+, recommission it using the approved APIC process. Verify the same node identity, software and module health, neighbor restoration, traffic rebalancing and endpoint reachability.

Now intentionally hold the fabric in its **inter-chassis mixed-generation** stage: **Spine-1 with SUP-A+; Spine-2 with SUP-A**, on a mutually supported current ACI release.

Check this as a **distinct acceptance gate**. Measure traffic again, validate COOP/IS-IS and applicable route reflection, look for new APIC faults, and confirm all forwarding paths have returned. A SUP-A/SUP-A+ pairing **inside one chassis** is not a normal steady-state supported pair: use the documented upgrade sequence, not an ad hoc persistent mixed pair.

**Stop if:** the recommissioned spine never reaches a healthy state, expected control-plane roles are missing, or the mixed-generation fabric does not meet the agreed traffic thresholds.

### Gate 5 — Repeat on second spine, then restore full redundancy

Only once Gate 4 passes should the second spine enter maintenance. Repeat the same observation points, even if the first swap was smooth: the second replacement might contain a different BIOS or image, and the other spine is now the sole remaining path.

After both SUP-A+ spines are back, re-run the original baseline tests and compare observed counters, peer state, endpoint behavior, application traffic and faults. An additional controlled reboot of the recovered SUP-A+ (in the lab) demonstrates that the image and boot variables survive past the one successful initial boot.

**Do not collapse the later ACI software upgrade into this same success claim.** Treat it as a separate validation cycle with its own prerequisites, mixed-software-version constraints and rollback model.

## 5. The test matrix: turn risks into executable cases

| ID | Test / failure mode | What this must prove | Priority |
| --- | --- | --- | --- |
| TV-01 | Full hardware/target-release compatibility | No unsupported dependencies missed | Critical |
| TV-02 | Two-spine baseline under representative flows | Starting state and repeatable measurements | Critical |
| TV-03 | Decommission first spine under load | Measured interruption/reconvergence | Critical |
| TV-04 | Steady one-spine operation at peak/bursty demand | Surviving path has adequate capacity | Critical |
| TV-05 | Normal SUP-A+ image, boot and role recovery | Happy path is repeatable | High |
| TV-06 | Replacement arrives NX-OS-only | Approved no-USB ACI recovery works | Critical |
| TV-07 | Wrong/older ACI image on incoming supervisor | Correct version selection and boot behavior | High |
| TV-08 | No usable bootflash ACI image; EOBC required | Transfer/boot/image persistence is recoverable | Critical |
| TV-09 | EOBC TFTP access violation | Root cause isolated and mitigation retested | Critical |
| TV-10 | Stuck loader / applicable force-download or BIOS branch | Recovery path is safe and feasible | High |
| TV-11 | First upgraded spine rejoins | Control and data planes restore | Critical |
| TV-12 | SUP-A+ and SUP-A in separate spine chassis | Mixed-generation stage is stable | Critical |
| TV-13 | Second spine refresh | Steps remain valid with reverse maintenance roles | Critical |
| TV-14 | Abort/rollback at agreed checkpoints | Restoration feasible within maintenance budget | Critical |
| TV-15 | Final regression and fabric/traffic comparison | No unexplained residual regression | Critical |
| TV-16 | Subsequent ACI upgrade on SUP-A+ | Independently qualified, supported software upgrade | Separate cycle |

Each test case should contain **preconditions, exact trigger, expected behavior, measurement source, stop conditions, recovery path, actual observation and linked evidence**. A checklist saying "pass" with no packet counters, logs, versions or event timeline is weak evidence.

## 6. Plan rollback before planning the happy path

Rollback is not a single vague step. Identify **where** in the procedure it may be needed and whether the original SUP-A can still be used with the **currently installed** software.

| Failure checkpoint | Recovery decision to pre-approve |
| --- | --- |
| Remaining spine cannot carry traffic | Stop before removing hardware; restore target spine through documented recommission path |
| New SUP-A+ fails to boot | Limit recovery attempts; use tested no-USB recovery or abort with TAC |
| EOBC path fails / TFTP error | Do not guess file permissions in production; invoke qualified alternate/reversal path |
| Spine boots but fabric state is unhealthy | Hold the second-spine change; investigate/recommission or restore according to MoP |
| Mixed-generation fabric fails validation | Stop before beginning second replacement; restore known-good state |
| Second replacement fails | Keep first upgraded spine available; use the specific second-spine abort procedure |
| Future software upgrade completed | **Re-evaluate** rollback; reinstalling unsupported SUP-A may no longer be possible |

Add a **time budget** to each branch: latest point to start recovery, latest acceptable recommissioning time, and the escalation threshold. Derive these from rehearsals, not guesses. Cisco's document notes that decommissioning triggers a reboot and recommissioning takes time; those are procedural observations, **not** customer outage guarantees.

## 7. Evidence that should accompany the customer recommendation

I would want the final validation package to contain:

1. **Configuration and compatibility sheet:** exact chassis PIDs, supervisor slots, modules, BIOS, APIC/ACI switch versions, supported-image mapping, feature dependencies.
2. **Lab equivalence statement:** what is representative of production, what differs, and how any coverage gaps affect confidence.
3. **Traffic test profile:** endpoints, leaf placement, flows, load model, packet sizes, SLOs and continuous captures.
4. **Before/during/after evidence:** timestamped APIC snapshots, module and diagnostics output, routing/COOP checks, fault deltas, interface counters, traffic charts.
5. **Boot-path evidence:** incoming SUP-A+ image/BIOS inventory, loader and EOBC transcripts, tested transfer and boot-variable behavior, repeat boot verification.
6. **Test execution register:** PASS / FAIL / BLOCKED / NOT TESTED, defect links, reproducer, fix, retest and evidence location.
7. **Approved MoP and recovery tree:** exact operator checkpoints, verified commands, stop/go and escalation decisions, time limits, named owners.
8. **Residual risk register:** tests that could not be done, assumptions about production load, support questions and explicit customer acceptance.

### Example evidence record for one case

```yaml
test_id: TV-09
scenario: "EOBC recovery with incoming SUP-A+ lacking matching ACI image"
prerequisites:
  - "Target spine decommissioned in lab"
  - "Known-good active supervisor on required current ACI software"
  - "Console capture and synchronized timestamps enabled"
  - "USB unavailable, matching customer policy"
stimulus: "Attempt documented EOBC image recovery"
observed:
  request: "/img-sync/curr-ks.img"
  error: "TFTP error 2 (Access violation)"
status: "FAIL - root cause not yet proven"
next_steps:
  - "Examine server-side image serving and permitted file access"
  - "Confirm exact chassis/release recovery guidance with Cisco TAC"
  - "Retest corrective action and cold boot persistence"
customer_impact: "Unqualified recovery path could extend maintenance window"
```

This record makes the observed outcome explicit without inventing a fix or falsely declaring the customer rollout ready.

## 8. Production-readiness decision: go, conditional go, or no-go

**Go** only if all critical tests have passed with linked evidence, load and interruption are inside agreed thresholds, recovery without USB is demonstrated for the expected incoming-image condition, the exact hardware/software matrix is supported, and the MoP plus rollback tree has been accepted.

**Conditional go** may be appropriate only where the customer explicitly accepts a bounded residual risk and a technically sound compensating control exists. A missing critical recovery method is not a good candidate for informal risk acceptance.

**No-go** if the remaining spine cannot support the expected demand, EOBC or alternate no-USB recovery remains unqualified, hardware compatibility is unresolved, a needed control-plane function is unstable, or the rollback plan cannot fit the approved change window.

For this case, I would treat **TV-04 (single-spine capacity)** and **TV-08/TV-09 (no-USB recovery)** as two of the highest-value tests: one protects customer traffic and the other protects the maintenance team's ability to finish or recover.

## What this exercise taught me about validation

The most useful moments in a validation cycle often happen when an assumption breaks. A replacement supervisor that arrives with the wrong image is one such moment. An EOBC loader showing an access violation is another. So is a two-spine fabric that must keep serving applications while one spine is decommissioned.

These observations should influence the MoP, the prerequisites, the fallback options and the confidence statement we provide to the customer.

I want a customer to leave this exercise with something stronger than "Cisco documents the replacement" or "the supervisor booted in our lab." I want them to know **which scenarios we tested, which risks we measured, what happens when a step fails, and where our evidence stops**.

That is the art of testing and validation.

---

## Official references and scope notes

- [Cisco N9508 ACI-Mode Hardware Installation Guide — supervisor replacement and upgrade](https://www.cisco.com/c/en/us/td/docs/switches/datacenter/nexus9000/hw/aci_9508_hig/guide/b_n9508_aci-mode_hardware_install_guide/m_install_n95xx_modules_aci.html)
- [Cisco N9504 ACI-Mode Hardware Installation Guide — supervisor replacement and upgrade](https://www.cisco.com/c/en/us/td/docs/switches/datacenter/nexus9000/hw/aci_9504_hig/guide/b_n9504_aci-mode_hardware_install_guide/replacing-or-installing-modules-fan-trays-power-supplies.html)
- [Cisco ACI-Mode Switches 16.1(5) Release Notes — supported and unsupported hardware](https://www.cisco.com/c/en/us/td/docs/dcn/aci/apic/6x/release-notes/cisco-aci-nx-os-release-notes-1615.html)
- [Cisco — Troubleshoot ACI Switch Baseline Health Using CLI Commands](https://www.cisco.com/c/en/us/support/docs/cloud-systems-management/application-policy-infrastructure-controller-apic/225960-troubleshoot-aci-switch-baseline-health.html)

**Engineering note:** Any particular command sequence, especially BIOS flashing, force-download, or privileged image permissions, must be approved for the exact chassis, ACI image, and support context. The examples here are for planning and validation, not a substitute for a customer-specific, Cisco-reviewed Method of Procedure.
