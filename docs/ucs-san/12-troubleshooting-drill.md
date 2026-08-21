# 12. Module 11 — Troubleshooting Drill (Bonus)

Work these as tickets — hints only, no direct answers, so you're practicing diagnosis rather than recall. Time-box each to 10–15 minutes before checking the answer key in 12.2.

1. A blade's vHBA never appears in `show flogi database` on N5K-3, but the FI shows the vNIC/vHBA as "Up" in UCSM.
2. `show zoneset active vsan 100` shows the correct zone, but the storage array reports no LUN visible to that WWPN.
3. An Ethernet port channel to FI-A shows one member `(I)` individual, one member `(P)` bundled.
4. After converting unified ports on N5K-3 from Ethernet to FC, the new FC ports don't appear in `show interface brief`.
5. Fabric B's storage path was working yesterday; today `show npv flogi-table` on FI-B is empty, though the physical link is up/up.
6. Two blades on VLAN 50 report no DHCP lease and can't reach the default gateway, while every other blade in the same chassis, on the same fabric, over the same physical uplink works normally.

## 12.1 Hints (open only if stuck)

??? tip "Ticket 1 hint"
    Check VSAN membership on the physical interface, and confirm `feature npiv` is enabled on N5K-3.

??? tip "Ticket 2 hint"
    Zoning is necessary but not sufficient — LUN masking on the array is a second, independent gate.

??? tip "Ticket 3 hint"
    Compare channel-mode (`active`/`passive`/`on`) and speed/duplex between the two members; a parameter mismatch keeps one member out of the bundle.

??? tip "Ticket 4 hint"
    Unified port conversions require a module reload/reboot to take effect — confirm it was actually applied and the module reloaded.

??? tip "Ticket 5 hint"
    Check whether the VSAN was deleted or its FCoE VLAN mapping changed upstream, and whether the uplink is still assigned to that VSAN under SAN Cloud.

??? tip "Ticket 6 hint"
    Same fault pattern as Task 7.4 — the fact that it's scoped to a specific VLAN, not a specific port or blade, tells you where to look before you run a single command. Compare the affected service profiles' vNIC VLAN against the upstream N5K uplink's allowed-list, not the FI side.

## 12.2 Answer-Key Checkpoints

Rather than full solutions (you'll get more value working these yourself), confirm your fix against these expected end-states:

??? success "Ticket 1 checkpoint"
    `show flogi database vsan 100` lists the blade's pWWN once the interface is in the correct VSAN with NPIV enabled.

??? success "Ticket 2 checkpoint"
    LUN becomes visible only after both zoning *and* array-side masking reference the same WWPN.

??? success "Ticket 3 checkpoint"
    `show port-channel summary` shows both members `(P)` once channel-mode and interface parameters match.

??? success "Ticket 4 checkpoint"
    `show port-resource module` confirms FC personality only after the module reload completes.

??? success "Ticket 5 checkpoint"
    `show npv flogi-table` repopulates once the uplink is correctly reassigned to the VSAN/FCoE VLAN pairing.

??? success "Ticket 6 checkpoint"
    `show interface trunk` on the affected N5K uplink lists VLAN 50 in "Vlans Allowed on Trunk" only after `switchport trunk allowed vlan add 50`; the two blades regain DHCP/gateway reachability with no change made on the FI side at all.
