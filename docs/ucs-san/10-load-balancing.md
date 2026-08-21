# 10. Module 9 — Load Balancing (5.1.e)

**Objective:** confirm traffic is actually spread across bundled links and across fabrics, not just theoretically capable of it.

## 10.1 Task 9.1 — Ethernet Port-Channel Hashing

```text
port-channel load-balance ethernet source-dest-port
show port-channel load-balance
```

(This is Nexus 5000 syntax — the `ethernet <keyword>` form. Nexus 7000/9000 platforms use a different keyword style, e.g. `src-dst ip-l4port`; don't mix the two.)

Pick a hash that includes L4 port when traffic is mostly IP flows between the same host pairs, so a small number of conversations don't all land on one member link.

## 10.2 Task 9.2 — FC Port-Channel Load Balancing

FC port channels load-balance per-exchange by default (OX_ID-based), which is almost always correct; per-flogi is available for edge cases where in-order delivery across the whole channel matters more than distribution. Check current mode:

```text
show san-port-channel summary
```

## 10.3 Task 9.3 — UCS-Side Pinning and Failover

Two distinct mechanisms, don't conflate them:

- **vNIC Fabric Failover** (a per-vNIC checkbox in the service profile): if the *primary* fabric's uplink fails, the vNIC's MAC moves to the other fabric's FI. This is a failover mechanism, not load balancing — only one fabric carries that vNIC's traffic at a time.
- **Dynamic pinning / static pinning** of vNICs and vHBAs to specific uplink ports or port channels (**LAN/SAN > Policies > Pin Groups**): this is how UCSM spreads *multiple* vNICs/vHBAs across *multiple* uplinks for aggregate bandwidth, since a single vNIC's traffic itself is not split across links.

## 10.4 Task 9.4 — VLAN Groups as a Traffic-Engineering Tool (ties back to Module 2.4)

Port-channel hashing (10.1) balances flows *within* one bundle; it says nothing about which uplink a given VLAN's traffic prefers in the first place. That's what the VLAN Groups from Module 2.4 are for: pinning `VG-Data` (VLAN 10) to the uplink facing FI-A and `VG-Mgmt` (VLAN 11) to the uplink facing FI-B gives each VLAN a deterministic *primary* path, splitting normal-condition load across two physically separate uplinks by VLAN — a coarse, policy-driven form of load distribution that complements, rather than duplicates, the hash-based balancing inside each bundle. Because both VLANs stay trunked on both uplinks, this is a preference, not a hard split: either one keeps working over the other uplink if its pinned path fails.

Confirm this is actually happening rather than assumed: on N5K-1, `show interface Ethernet1/1 counters` (or `show interface counters trunk`) should show VLAN 10's traffic dominating its pinned uplink under normal conditions, with VLAN 11 doing the same on its own pinned uplink — not a hard zero on the non-preferred side, since both VLANs remain permitted on both trunks.

!!! question "Check yourself"
    If you skipped VLAN Groups and just let both VLANs hash across both uplinks with no pinning preference at all, what specifically would you lose from a troubleshooting and change-control standpoint, even if raw throughput ended up about the same?

!!! question "Check yourself"
    If a blade has only one vNIC per fabric, does enabling more uplink ports in that fabric's port channel increase that vNIC's individual throughput? Why or why not — and what would you add to actually increase it?
