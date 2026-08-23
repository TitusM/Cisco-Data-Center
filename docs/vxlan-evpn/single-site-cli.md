# VXLAN BGP EVPN (CLI) — Single Site

Configuration and verification of a single-site VXLAN BGP EVPN fabric using the NX-OS CLI.

For more labs visit my GitHub repo: [https://github.com/TitusM/Cisco-Data-Center](https://github.com/TitusM/Cisco-Data-Center)

![VXLAN BGP EVPN single-site lab cover](../assets/vxlan-single-site-cli/img-005.png)

!!! note
    This lab was conducted in a controlled environment. Any configurations in a production network should be implemented during a designated maintenance window. Additionally, always refer to official Cisco documentation relevant to your specific hardware and software.

## Introduction

Virtual Extensible LAN (VXLAN) provides a mechanism to extend Layer 2 networks across a Layer 3 infrastructure using MAC-in-UDP encapsulation and tunnelling. This technology enables the creation of virtualized and multitenant data center fabrics over a shared physical infrastructure. VXLAN enhances workload mobility and flexibility by extending Layer 2 segments across the Layer 3 underlay network.

This lab demonstrates the complete configuration workflow for building a VXLAN fabric underlay and overlay, including the setup required for intra-VNI (Layer 2) and inter-VNI (Layer 3) communication using an L3 VNI. The lab also includes detailed verification steps at each stage of configuration. Additionally, a Wireshark capture is provided to illustrate how a packet from a local endpoint is encapsulated and transported through the VXLAN fabric to reach a remote endpoint.

## VXLAN Encapsulation and Packet Format

VXLAN defines a MAC-in-UDP encapsulation scheme where the original Layer 2 frame has a VXLAN header added and is then placed in a UDP-IP packet. With this MAC-in-UDP encapsulation, VXLAN tunnels a Layer 2 network over a Layer 3 network.

??? info "VXLAN header and encapsulation format"

    VXLAN uses an 8-byte VXLAN header that consists of a 24-bit VNID and a few reserved bits. The VXLAN header, together with the original Ethernet frame, go inside the UDP payload. The 24-bit VNID is used to identify Layer 2 segments and to maintain Layer 2 isolation between the segments. With all 24 bits in the VNID, VXLAN can support 16 million LAN segments.

    The following captures provide complementary views of the same VXLAN-encapsulated Ethernet frame.

    ![VXLAN-encapsulated Ethernet frame — exhibit 1](../assets/vxlan-single-site-cli/img-007.png)

    ![VXLAN-encapsulated Ethernet frame — exhibit 2](../assets/vxlan-single-site-cli/img-009.png)

    ![VXLAN-encapsulated Ethernet frame — exhibit 3](../assets/vxlan-single-site-cli/img-011.png)

## Lab Topology

![Single-site VXLAN BGP EVPN lab topology](../assets/vxlan-single-site-cli/img-013.png)

## Underlay Unicast Routing

The underlay network in a VXLAN BGP EVPN fabric is a routed IP network that provides Layer 3 connectivity between the VTEPs (VXLAN Tunnel Endpoints). It is responsible for forwarding unicast traffic between VTEPs through VXLAN tunnels.

In this design, VXLAN-encapsulated packets are transported across the underlay based on the outer IP header. The source IP address in the outer header represents the initiating VTEP's loopback interface, while the destination IP address corresponds to the terminating VTEP's loopback interface. The underlay therefore ensures efficient IP-based transport of VXLAN traffic across the fabric, independent of the tenant's Layer 2 or Layer 3 topology.

This lab uses OSPF as the underlay routing protocol.

![Underlay OSPF topology](../assets/vxlan-single-site-cli/img-015.png)

### Configure OSPF

=== "SPINE-1"

    ```text
    feature ospf
    !
    interface Ethernet1/3
      description to leaf-2
      mtu 9216
      ip address 10.14.14.1/30
      ip ospf network point-to-point
      ip router ospf UNDERLAY area 0.0.0.0
      no shutdown
    !
    interface Ethernet1/4
      description to leaf-1
      mtu 9216
      ip address 10.13.13.1/30
      ip ospf network point-to-point
      ip router ospf UNDERLAY area 0.0.0.0
      no shutdown
    !
    interface loopback0
      description for-vtep-reachability
      ip address 1.1.1.1/32
      ip router ospf UNDERLAY area 0.0.0.0
    !
    interface loopback1
      description for-mcast
      ip address 12.12.12.12/32
      ip router ospf UNDERLAY area 0.0.0.0
    ```

=== "SPINE-2"

    ```text
    feature ospf
    !
    interface Ethernet1/3
      description to leaf-1
      mtu 9216
      ip address 10.23.23.1/30
      ip ospf network point-to-point
      ip router ospf UNDERLAY area 0.0.0.0
      no shutdown
    !
    interface Ethernet1/4
      description to leaf-2
      mtu 9216
      ip address 10.24.24.1/30
      ip ospf network point-to-point
      ip router ospf UNDERLAY area 0.0.0.0
      no shutdown
    !
    interface loopback0
      description for-vtep-reachability
      ip address 2.2.2.2/32
      ip router ospf UNDERLAY area 0.0.0.0
    !
    interface loopback1
      description for-mcast
      ip address 12.12.12.12/32
      ip router ospf UNDERLAY area 0.0.0.0
    ```

=== "LEAF-1"

    ```text
    feature ospf
    !
    interface Ethernet1/3
      description to spine-2
      mtu 9216
      ip address 10.23.23.2/30
      ip ospf network point-to-point
      ip router ospf UNDERLAY area 0.0.0.0
      no shutdown
    !
    interface Ethernet1/4
      description to spine-1
      mtu 9216
      ip address 10.13.13.2/30
      ip ospf network point-to-point
      ip router ospf UNDERLAY area 0.0.0.0
      no shutdown
    !
    interface loopback0
      description for-vtep-reachability
      ip address 3.3.3.3/32
      ip router ospf UNDERLAY area 0.0.0.0
    !
    interface loopback1
      description for-vni-peering
      ip address 33.33.33.33/32
      ip router ospf UNDERLAY area 0.0.0.0
    ```

=== "LEAF-2"

    ```text
    feature ospf
    !
    interface Ethernet1/3
      description to spine-1
      mtu 9216
      ip address 10.14.14.2/30
      ip ospf network point-to-point
      ip router ospf UNDERLAY area 0.0.0.0
      no shutdown
    !
    interface Ethernet1/4
      description to spine-2
      mtu 9216
      ip address 10.24.24.2/30
      ip ospf network point-to-point
      ip router ospf UNDERLAY area 0.0.0.0
      no shutdown
    !
    interface loopback0
      description for-vtep-reachability
      ip address 4.4.4.4/32
      ip router ospf UNDERLAY area 0.0.0.0
    !
    interface loopback1
      description for-vni-peering
      ip address 44.44.44.44/32
      ip router ospf UNDERLAY area 0.0.0.0
    ```

### Verify OSPF Adjacencies

Confirm that each device has formed the expected OSPF adjacencies and that all neighbors are in the `FULL` state.

=== "SPINE-1"

    ```text
    spine-1# show ip ospf neighbors
    OSPF Process ID UNDERLAY VRF default
    Total number of neighbors: 2
    Neighbor ID     Pri State            Up Time      Address           Interface
    4.4.4.4           1 FULL/ -          3d13h        10.14.14.2        Eth1/3
    3.3.3.3           1 FULL/ -          3d13h        10.13.13.2        Eth1/4
    ```

=== "SPINE-2"

    ```text
    spine-2# show ip ospf neighbors
    OSPF Process ID UNDERLAY VRF default
    Total number of neighbors: 2
    Neighbor ID     Pri State            Up Time      Address           Interface
    3.3.3.3           1 FULL/ -          3d13h        10.23.23.2        Eth1/3
    4.4.4.4           1 FULL/ -          3d13h        10.24.24.2        Eth1/4
    ```

=== "LEAF-1"

    ```text
    leaf-1# show ip ospf neighbors
    OSPF Process ID UNDERLAY VRF default
    Total number of neighbors: 2
    Neighbor ID     Pri State            Up Time      Address           Interface
    2.2.2.2           1 FULL/ -          3d13h        10.23.23.1        Eth1/3
    1.1.1.1           1 FULL/ -          3d13h        10.13.13.1        Eth1/4
    ```

=== "LEAF-2"

    ```text
    leaf-2# show ip ospf neighbors
    OSPF Process ID UNDERLAY VRF default
    Total number of neighbors: 2
    Neighbor ID     Pri State            Up Time      Address           Interface
    1.1.1.1           1 FULL/ -          3d13h        10.14.14.1        Eth1/3
    2.2.2.2           1 FULL/ -          3d13h        10.24.24.1        Eth1/4
    ```

!!! success "Checkpoint"
    All OSPF neighbor states should show `FULL` before continuing to the multicast underlay configuration.

## Underlay Multicast Routing

Underlay multicast routing is used to handle Broadcast, Unknown-unicast, and Multicast (BUM) traffic.

??? info "PIM ASM and Anycast-RP in this lab"

    This lab uses PIM ASM Sparse Mode. PIM Sparse Mode creates one source tree per VTEP per multicast group. The PIM Sparse Mode uses PIM Anycast RP (RFC 4610) for RP redundancy. In a VXLAN fabric, the spines serve as RPs for the underlay.

### Configure PIM

=== "SPINE-1"

    ```text
    feature pim
    !
    ip pim rp-address 12.12.12.12 group-list 239.0.0.0/24
    ip pim anycast-rp 12.12.12.12 1.1.1.1 <spine-1 lo0>
    ip pim anycast-rp 12.12.12.12 2.2.2.2 <spine-2 lo0>
    !
    interface Ethernet1/3
      ip pim sparse-mode
    !
    interface Ethernet1/4
      ip pim sparse-mode
    !
    interface loopback0
      ip pim sparse-mode
    !
    interface loopback1
      ip pim sparse-mode
    ```

=== "SPINE-2"

    ```text
    feature pim
    !
    ip pim rp-address 12.12.12.12 group-list 239.0.0.0/24
    ip pim anycast-rp 12.12.12.12 1.1.1.1 <lo1 – spine-1&2>
    ip pim anycast-rp 12.12.12.12 2.2.2.2
    !
    interface Ethernet1/3
      ip pim sparse-mode
    !
    interface Ethernet1/4
      ip pim sparse-mode
    !
    interface loopback0
      ip pim sparse-mode
    !
    interface loopback1
      ip pim sparse-mode
    ```

=== "LEAF-1"

    ```text
    feature pim
    !
    ip pim rp-address 12.12.12.12 group-list 239.0.0.0/24
    !
    interface Ethernet1/3
      ip pim sparse-mode
    !
    interface Ethernet1/4
      ip pim sparse-mode
    !
    interface loopback0
      ip pim sparse-mode
    !
    interface loopback1
      ip pim sparse-mode
    ```

=== "LEAF-2"

    ```text
    feature pim
    !
    ip pim rp-address 12.12.12.12 group-list 239.0.0.0/24
    !
    interface Ethernet1/3
      ip pim sparse-mode
    !
    interface Ethernet1/4
      ip pim sparse-mode
    !
    interface loopback0
      ip pim sparse-mode
    !
    interface loopback1
      ip pim sparse-mode
    ```

### Verify PIM Neighbors

=== "SPINE-1"

    ```text
    spine-1# show ip pim neighbor
    PIM Neighbor Status for VRF "default"
    Neighbor        Interface             Uptime    Expires    DR       Bidir- BFD      ECMP Redirect
                                                                Priority Capable State       Capable
    10.14.14.2       Ethernet1/3          3d15h     00:01:34   1        yes     n/a      no
    10.13.13.2       Ethernet1/4          3d15h     00:01:31   1        yes     n/a      no
    ```

=== "SPINE-2"

    ```text
    spine-2# show ip pim neighbor
    PIM Neighbor Status for VRF "default"
    Neighbor        Interface             Uptime    Expires    DR       Bidir- BFD      ECMP Redirect
                                                                Priority Capable State       Capable
    10.23.23.2       Ethernet1/3          3d15h     00:01:20   1        yes     n/a      no
    10.24.24.2       Ethernet1/4          3d15h     00:01:33   1        yes     n/a      no
    ```

=== "LEAF-1"

    ```text
    leaf-1# show ip pim neighbor
    PIM Neighbor Status for VRF "default"
    Neighbor        Interface             Uptime    Expires    DR       Bidir- BFD      ECMP Redirect
                                                                Priority Capable State       Capable
    10.23.23.1       Ethernet1/3          3d15h     00:01:18   1        yes     n/a      no
    10.13.13.1       Ethernet1/4          3d15h     00:01:28   1        yes     n/a      no
    ```

=== "LEAF-2"

    ```text
    leaf-2# show ip pim neighbor
    PIM Neighbor Status for VRF "default"
    Neighbor        Interface             Uptime    Expires    DR       Bidir- BFD      ECMP Redirect
                                                                Priority Capable State       Capable
    10.14.14.1       Ethernet1/3          3d15h     00:01:41   1        yes     n/a      no
    10.24.24.1       Ethernet1/4          3d15h     00:01:40   1        yes     n/a      no
    ```

### Verify RP Status

=== "SPINE-1"

    ```text
    spine-1# show ip pim rp
    PIM RP Status Information for VRF "default"
    BSR disabled
    Auto-RP disabled
    BSR RP Candidate policy: None
    BSR RP policy: None
    Auto-RP Announce policy: None
    Auto-RP Discovery policy: None

    Anycast-RP 12.12.12.12 members:
      1.1.1.1* 2.2.2.2

    RP: 12.12.12.12*, (0),
     uptime: 3d17h   priority: 255,
     RP-source: (local),
     group ranges:
     239.0.0.0/24
    ```

=== "SPINE-2"

    ```text
    spine-2# show ip pim rp
    PIM RP Status Information for VRF "default"
    BSR disabled
    Auto-RP disabled
    BSR RP Candidate policy: None
    BSR RP policy: None
    Auto-RP Announce policy: None
    Auto-RP Discovery policy: None

    Anycast-RP 12.12.12.12 members:
      1.1.1.1 2.2.2.2*

    RP: 12.12.12.12*, (0),
     uptime: 3d03h   priority: 255,
     RP-source: (local),
     group ranges:
     239.0.0.0/24
    ```

=== "LEAF-1"

    ```text
    leaf-1# show ip pim rp
    PIM RP Status Information for VRF "default"
    BSR disabled
    Auto-RP disabled
    BSR RP Candidate policy: None
    BSR RP policy: None
    Auto-RP Announce policy: None
    Auto-RP Discovery policy: None

    RP: 12.12.12.12, (0),
     uptime: 3d03h   priority: 255,
     RP-source: (local),
     group ranges:
     239.0.0.0/24
    ```

=== "LEAF-2"

    ```text
    leaf-2# show ip pim rp
    PIM RP Status Information for VRF "default"
    BSR disabled
    Auto-RP disabled
    BSR RP Candidate policy: None
    BSR RP policy: None
    Auto-RP Announce policy: None
    Auto-RP Discovery policy: None

    RP: 12.12.12.12, (0),
     uptime: 3d03h   priority: 255,
     RP-source: (local),
     group ranges:
     239.0.0.0/24
    ```

### Verify the Multicast Routing Table

=== "LEAF-1"

    ```text
    leaf-1# show ip mroute
    IP Multicast Routing Table for VRF "default"

    (*, 232.0.0.0/8), uptime: 3d14h, pim ip
      Incoming interface: Null, RPF nbr: 0.0.0.0
      Outgoing interface list: (count: 0)

    (*, 239.0.0.1/32), uptime: 3d14h, nve pim ip
      Incoming interface: Ethernet1/3, RPF nbr: 10.23.23.1
      Outgoing interface list: (count: 1)
        nve1, uptime: 3d14h, nve

    (33.33.33.33/32, 239.0.0.1/32), uptime: 3d14h, nve mrib pim ip
      Incoming interface: loopback1, RPF nbr: 33.33.33.33
      Outgoing interface list: (count: 1)
        Ethernet1/4, uptime: 3d14h, pim
    ```

=== "LEAF-2"

    ```text
    leaf-2# show ip mroute
    IP Multicast Routing Table for VRF "default"

    (*, 232.0.0.0/8), uptime: 3d14h, pim ip
      Incoming interface: Null, RPF nbr: 0.0.0.0
      Outgoing interface list: (count: 0)

    (*, 239.0.0.1/32), uptime: 3d14h, nve pim ip
      Incoming interface: Ethernet1/3, RPF nbr: 10.14.14.1
      Outgoing interface list: (count: 1)
        nve1, uptime: 3d14h, nve

    (44.44.44.44/32, 239.0.0.1/32), uptime: 3d14h, nve mrib pim ip
      Incoming interface: loopback1, RPF nbr: 44.44.44.44
      Outgoing interface list: (count: 1)
        Ethernet1/4, uptime: 2d15h, pim
    ```

!!! success "Checkpoint"
    PIM neighbors should be established on every underlay-facing interface and each anycast-RP member should show the local RP as active before configuring the EVPN overlay.

## Overlay Unicast Routing (Control Plane)

In this lab, iBGP is configured between the spines and the leaves — the leaves and spines are part of the same autonomous system. The spines are configured as BGP route-reflectors. The spine's role in the EVPN overlay is to take the routes learned from each leaf and propagate them to the other leaves in the fabric. Using BGP EVPN as the control plane in the fabric allows for route learning, route distribution, and VXLAN peer discovery.

![BGP EVPN control-plane topology](../assets/vxlan-single-site-cli/img-021.png)

### Configure BGP EVPN

=== "SPINE-1"

    ```text
    nv overlay evpn
    !
    router bgp 65000
      address-family l2vpn evpn
      neighbor 3.3.3.3
        remote-as 65000
        update-source loopback0
        address-family l2vpn evpn
          send-community
          send-community extended
          route-reflector-client
      neighbor 4.4.4.4
        remote-as 65000
        update-source loopback0
        address-family l2vpn evpn
          send-community
          send-community extended
          route-reflector-client
    ```

=== "SPINE-2"

    ```text
    nv overlay evpn
    !
    router bgp 65000
      address-family l2vpn evpn
      neighbor 3.3.3.3
        remote-as 65000
        update-source loopback0
        address-family l2vpn evpn
          send-community
          send-community extended
          route-reflector-client
      neighbor 4.4.4.4
        remote-as 65000
        update-source loopback0
        address-family l2vpn evpn
          send-community
          send-community extended
          route-reflector-client
    ```

=== "LEAF-1"

    ```text
    feature bgp
    feature nv overlay
    !
    route-map PERMIT-ALL
    ! route-map to redistribute directly connected routes in the BGP instance
    !
    router bgp 65000
      address-family l2vpn evpn
      neighbor 1.1.1.1
        remote-as 65000
        update-source loopback0
        address-family l2vpn evpn
          send-community
          send-community extended
      neighbor 2.2.2.2
        remote-as 65000
        update-source loopback0
        address-family l2vpn evpn
          send-community
          send-community extended
      vrf tenant-1
        address-family ipv4 unicast
          redistribute direct route-map PERMIT-ALL
    ```

=== "LEAF-2"

    ```text
    feature bgp
    feature nv overlay
    !
    route-map PERMIT-ALL
    ! route-map to redistribute directly connected routes in the BGP instance
    !
    router bgp 65000
      address-family l2vpn evpn
      neighbor 1.1.1.1
        remote-as 65000
        update-source loopback0
        address-family l2vpn evpn
          send-community
          send-community extended
      neighbor 2.2.2.2
        remote-as 65000
        update-source loopback0
        address-family l2vpn evpn
          send-community
          send-community extended
      vrf tenant-1
        address-family ipv4 unicast
          redistribute direct route-map PERMIT-ALL
    ```

### Verify BGP EVPN Sessions

Confirm that each device has the expected number of established EVPN peers.

=== "SPINE-1"

    ```text
    spine-1# show bgp l2vpn evpn summary
    BGP summary information for VRF default, address family L2VPN EVPN
    BGP router identifier 1.1.1.1, local AS number 65000
    BGP table version is 39, L2VPN EVPN config peers 2, capable peers 2
    6 network entries and 6 paths using 1536 bytes of memory
    BGP attribute entries [5/920], BGP AS path entries [0/0]
    BGP community entries [0/0], BGP clusterlist entries [0/0]

    Neighbor         V    AS MsgRcvd MsgSent        TblVer    InQ OutQ Up/Down State/PfxRcd
    3.3.3.3          4 65000    5154    5166            39      0    0    3d01h 0
    4.4.4.4          4 65000    5151    5164            39      0    0    3d01h 0
    ```

=== "SPINE-2"

    ```text
    spine-2# show bgp l2vpn evpn summary
    BGP summary information for VRF default, address family L2VPN EVPN
    BGP router identifier 2.2.2.2, local AS number 65000
    BGP table version is 35, L2VPN EVPN config peers 2, capable peers 2
    6 network entries and 6 paths using 1752 bytes of memory
    BGP attribute entries [5/1800], BGP AS path entries [0/0]
    BGP community entries [0/0], BGP clusterlist entries [0/0]

    Neighbor         V    AS     MsgRcvd      MsgSent    TblVer     InQ OutQ Up/Down State/PfxRcd
    3.3.3.3          4 65000        5155         5164        35       0    0    3d01h 4
    4.4.4.4          4 65000        5154         5164        35       0    0    3d01h 2

    Neighbor         T    AS PfxRcd        Type-2       Type-3       Type-4     Type-5
    3.3.3.3          I 65000 0             0            0            0          0
    4.4.4.4          I 65000 0             0            0            0          0
    ```

=== "LEAF-1"

    ```text
    leaf-1# show bgp l2vpn evpn summary
    BGP summary information for VRF default, address family L2VPN EVPN
    BGP router identifier 3.3.3.3, local AS number 65000
    BGP table version is 28, L2VPN EVPN config peers 2, capable peers 2
    9 network entries and 11 paths using 2532 bytes of memory
    BGP attribute entries [11/4048], BGP AS path entries [0/0]
    BGP community entries [0/0], BGP clusterlist entries [2/8]

    Neighbor          V    AS         MsgRcvd      MsgSent    TblVer   InQ OutQ Up/Down State/PfxRcd
    1.1.1.1           4 65000            5118         5099        28     0    0    3d01h 2
    2.2.2.2           4 65000            5114         5101        28     0    0    3d01h 2

    Neighbor          T    AS PfxRcd            Type-2       Type-3    Type-4     Type-5     Type-12
    1.1.1.1           I 65000 0                 0            0         0          0          0
    2.2.2.2           I 65000 0                 0            0         0          0          0
    ```

=== "LEAF-2"

    ```text
    leaf-2# show bgp l2vpn evpn summary
    BGP summary information for VRF default, address family L2VPN EVPN
    BGP router identifier 4.4.4.4, local AS number 65000
    BGP table version is 27, L2VPN EVPN config peers 2, capable peers 2
    9 network entries and 12 paths using 2532 bytes of memory
    BGP attribute entries [12/4416], BGP AS path entries [0/0]
    BGP community entries [0/0], BGP clusterlist entries [2/8]

    Neighbor          V    AS         MsgRcvd      MsgSent    TblVer   InQ OutQ Up/Down State/PfxRcd
    1.1.1.1           4 65000            5121         5100        27     0    0    3d01h 0
    2.2.2.2           4 65000            5117         5103        27     0    0    3d01h 0

    Neighbor          T    AS PfxRcd            Type-2       Type-3    Type-4     Type-5     Type-12
    1.1.1.1           I 65000 0                 0            0         0          0          0
    2.2.2.2           I 65000 0                 0            0         0          0          0
    ```

!!! success "Checkpoint"
    All four devices should show their EVPN peers established (state `I` for iBGP with a non-zero `Up/Down` time) before configuring VLAN-to-VNI mapping.

## VLAN to VNI Mapping

=== "LEAF-1"

    ```text
    feature vn-segment-vlan-based
    !
    vlan 100
      vn-segment 1000
    !
    interface nve1
      no shutdown
      host-reachability protocol bgp
      source-interface loopback1
      member vni 1000
        mcast-group 239.0.0.1
    ```

=== "LEAF-2"

    ```text
    feature vn-segment-vlan-based
    !
    vlan 200
      vn-segment 1000
    !
    interface nve1
      no shutdown
      host-reachability protocol bgp
      source-interface loopback1
      member vni 1000
        mcast-group 239.0.0.1
    ```

!!! note
    The `vn-segment` command maps a VLAN to a specific VNI. This mapping is locally significant, meaning you can use different VLAN IDs on other switches. The VNI ID is the only parameter that is globally significant. The configured segments are associated with a multicast group for multi-destination traffic.

### Verify the NVE Interface Status

=== "LEAF-1"

    ```text
    leaf-1# show interface nve1
    nve1 is up
    admin state is up, Hardware: NVE
      MTU 9216 bytes
      Encapsulation VXLAN
    ```

=== "LEAF-2"

    ```text
    leaf-2# show interface nve1
    nve1 is up
    admin state is up, Hardware: NVE
      MTU 9216 bytes
      Encapsulation VXLAN
    ```

### Verify the NVE Interface Components

Check the VNIs associated with the NVE interface.

=== "LEAF-1"

    ```text
    leaf-1# show nve vni
    Codes: CP - Control Plane        DP - Data Plane
           UC - Unconfigured         SA - Suppress ARP
           S-ND - Suppress ND
           SU - Suppress Unknown Unicast
           Xconn - Crossconnect
           MS-IR - Multisite Ingress Replication
           HYB - Hybrid IRB mode

    Interface VNI      Multicast-group   State Mode Type [BD/VRF]      Flags
    --------- -------- ----------------- ----- ---- ------------------ -----
    nve1      1000     239.0.0.1         Up    CP   L2 [100]
    ```

=== "LEAF-2"

    ```text
    leaf-2# show nve vni
    Codes: CP - Control Plane        DP - Data Plane
           UC - Unconfigured         SA - Suppress ARP
           S-ND - Suppress ND
           SU - Suppress Unknown Unicast
           Xconn - Crossconnect
           MS-IR - Multisite Ingress Replication
           HYB - Hybrid IRB mode

    Interface VNI      Multicast-group   State Mode Type [BD/VRF]      Flags
    --------- -------- ----------------- ----- ---- ------------------ -----
    nve1      1000     239.0.0.1         Up    CP   L2 [200]
    ```

To verify the NVE peers on a VTEP, use `show nve peers`. Notice that the `LearnType` column shows `CP` — control-plane learning, meaning the NVE peer was learned dynamically using BGP EVPN.

=== "LEAF-1"

    ```text
    leaf-1# show nve peers
    Interface Peer-IP                                     State LearnType Uptime   Router-Mac
    --------- --------------------------------------      ----- --------- -------- -----------------
    nve1      44.44.44.44                                 Up    CP        3d00h    3488.1815.5425
    ```

=== "LEAF-2"

    ```text
    leaf-2# show nve peers
    Interface Peer-IP                                     State LearnType Uptime   Router-Mac
    --------- --------------------------------------      ----- --------- -------- -----------------
    nve1      33.33.33.33                                 Up    CP        3d00h    3488.1815.561f
    ```

### Verify VLAN-to-VNI Mapping

=== "LEAF-1"

    ```text
    leaf-1# show vlan id 100 vn-segment

    VLAN Segment-id
    ---- -----------
    100  1000
    ```

=== "LEAF-2"

    ```text
    leaf-2# show vlan id 200 vn-segment

    VLAN Segment-id
    ---- -----------
    200  1000
    ```

!!! success "Checkpoint"
    Both NVE interfaces should be `Up`, each should show VNI 1000 mapped to its local VLAN, and each leaf should have a `CP`-learned NVE peer for the remote VTEP.

## Layer 3 VNI Configuration

A Layer 3 VNI routes traffic between Layer 2 VNIs. The first step is to define the VRF (tenant) that the subnets will be members of. The L3 VNI is defined under the VRF context.

=== "LEAF-1"

    ```text
    vrf context tenant-1
      vni 50000 l3
      rd auto
      address-family ipv4 unicast
        route-target both auto
        route-target both auto evpn
    ```

=== "LEAF-2"

    ```text
    vrf context tenant-1
      vni 50000 l3
      rd auto
      address-family ipv4 unicast
        route-target both auto
        route-target both auto evpn
    ```

!!! note
    Beginning with Cisco NX-OS Release 10.2(3)F, the new L3VNI mode is supported on Cisco Nexus 9000 switches. The new CLI for L3 VNI does not require mapping a VLAN to the L3VNI, which also removes the requirement to provision an SVI interface — saving on VLANs and increasing the scale of VNIs supported on a given leaf node.

The L3 VNI is then associated with the VRF.

=== "LEAF-1"

    ```text
    interface nve1
      no shutdown
      member vni 50000 associate-vrf
    ```

=== "LEAF-2"

    ```text
    interface nve1
      no shutdown
      member vni 50000 associate-vrf
    ```

### Verify the VRF-to-VNI Association

=== "LEAF-1"

    ```text
    leaf-1# show nve vrf
    VRF-Name     VNI        Interface Gateway-MAC
    ------------ ---------- --------- -----------------
    tenant-1     50000      nve1      3488.1815.561f
    ```

=== "LEAF-2"

    ```text
    leaf-2# show nve vrf
    VRF-Name     VNI        Interface Gateway-MAC
    ------------ ---------- --------- -----------------
    tenant-1     50000      nve1      3488.1815.5425
    ```

### Verify the L3VNI Mode Configuration

=== "LEAF-1"

    ```text
    leaf-1# show nve vni
    Codes: CP - Control Plane        DP - Data Plane
           UC - Unconfigured         SA - Suppress ARP
           S-ND - Suppress ND
           SU - Suppress Unknown Unicast
           Xconn - Crossconnect
           MS-IR - Multisite Ingress Replication
           HYB - Hybrid IRB mode

    Interface VNI      Multicast-group   State Mode Type [BD/VRF]      Flags
    --------- -------- ----------------- ----- ---- ------------------ -----
    nve1      1000     239.0.0.1         Up    CP   L2 [100]
    nve1      50000    n/a               Up    CP   L3 [tenant-1]
    ```

=== "LEAF-2"

    ```text
    leaf-2# show nve vni
    Codes: CP - Control Plane        DP - Data Plane
           UC - Unconfigured         SA - Suppress ARP
           S-ND - Suppress ND
           SU - Suppress Unknown Unicast
           Xconn - Crossconnect
           MS-IR - Multisite Ingress Replication
           HYB - Hybrid IRB mode

    Interface VNI      Multicast-group   State Mode Type [BD/VRF]      Flags
    --------- -------- ----------------- ----- ---- ------------------ -----
    nve1      1000     239.0.0.1         Up    CP   L2 [200]
    nve1      50000    n/a               Up    CP   L3 [tenant-1]
    ```

!!! success "Checkpoint"
    Each leaf should show both the L2 VNI (1000) and the L3 VNI (50000) as `Up` on `nve1` before configuring the anycast gateway.

## Anycast Gateway Configuration

![Anycast gateway concept](../assets/vxlan-single-site-cli/img-027.png)

The Anycast Gateway feature is a default gateway-addressing mechanism that enables you to use the same gateway IP address across all the leaf switches that are part of a VXLAN network. Every VTEP is assigned the same anycast gateway MAC address for every L2 VNI SVI interface. This feature gives you the flexibility to place a workload on any leaf switch — it enables host mobility and optimal traffic forwarding.

=== "LEAF-1"

    ```text
    feature interface-vlan
    !
    fabric forwarding anycast-gateway-mac 0002.0002.0002
    !
    interface Vlan100
      no shutdown
      vrf member tenant-1
      ip address 100.1.0.254/24
      fabric forwarding mode anycast-gateway
    ```

=== "LEAF-2"

    ```text
    feature interface-vlan
    !
    fabric forwarding anycast-gateway-mac 0002.0002.0002
    !
    interface Vlan200
      no shutdown
      vrf member tenant-1
      ip address 100.1.0.254/24
      fabric forwarding mode anycast-gateway
    ```

### Verify the Anycast Gateway SVIs

=== "LEAF-1"

    ```text
    leaf-1# show ip interface brief vrf tenant-1
    IP Interface Status for VRF "tenant-1"(4)
    Interface          IP Address      Interface Status
    Vlan100            100.1.0.254     protocol-up/link-up/admin-up
    Vni50000           forward-enabled protocol-up/link-up/admin-up
    ```

=== "LEAF-2"

    ```text
    leaf-2# show ip interface brief vrf tenant-1
    IP Interface Status for VRF "tenant-1"(4)
    Interface          IP Address      Interface Status
    Vlan200            100.1.0.254     protocol-up/link-up/admin-up
    Vni50000           forward-enabled protocol-up/link-up/admin-up
    ```

!!! success "Checkpoint"
    Both leaves should present the same anycast gateway IP (`100.1.0.254`) as `protocol-up/link-up/admin-up` on their respective VLAN SVIs before validating end-to-end communication.

## Layer 2 Communication

![Layer 2 communication topology](../assets/vxlan-single-site-cli/img-028.png)

This section verifies endpoint learning on each switch, verifies endpoint communication across the fabric, and walks through the packet flow from the source endpoint to the destination endpoint across the fabric.

### Verify MAC Address Learning

Check the MAC address table on each leaf. The output shows that each leaf has MAC address information for its locally connected endpoint and for the remote endpoint learned via the control plane.

=== "LEAF-1"

    ```text
    leaf-1# show mac address-table dynamic
    Legend:
            * - primary entry, G - Gateway MAC, (R) - Routed MAC, O - Overlay MAC
            age - seconds since last seen,+ - primary entry using vPC Peer-Link,
            (T) - True, (F) - False, C - ControlPlane MAC, ~ - vsan,
            (NA)- Not Applicable A – ESI Active Path, S – ESI Standby Path
        VLAN     MAC Address      Type      age     Secure NTFY Ports
    ---------+-----------------+--------+---------+------+----+------------------
    C 100      00ee.abd0.9197   dynamic NA          F      F    nve1(44.44.44.44)
    * 100      10b3.d6cb.77e7   dynamic NA          F      F    Eth1/33
    ```

=== "LEAF-2"

    ```text
    leaf-2# show mac address-table dynamic
    Legend:
            * - primary entry, G - Gateway MAC, (R) - Routed MAC, O - Overlay MAC
            age - seconds since last seen,+ - primary entry using vPC Peer-Link,
            (T) - True, (F) - False, C - ControlPlane MAC, ~ - vsan,
            (NA)- Not Applicable A – ESI Active Path, S – ESI Standby Path
        VLAN     MAC Address      Type      age     Secure NTFY Ports
    ---------+-----------------+--------+---------+------+----+------------------
    * 200      00ee.abd0.9197   dynamic NA          F      F    Eth1/34
    C 200      10b3.d6cb.77e7   dynamic NA          F      F    nve1(33.33.33.33)
    ```

### Verify the Routing Table

The routing table on each leaf, for the tenant VRF, shows the endpoint IP addresses learned from BGP.

=== "LEAF-1"

    ```text
    leaf-1# show ip route vrf tenant-1
    IP Route Table for VRF "tenant-1"
    '*' denotes best ucast next-hop
    '[x/y]' denotes [preference/metric]
    '%<string>' in via output denotes VRF <string>

    100.1.0.0/24, ubest/mbest: 1/0, attached
        *via 100.1.0.254, Vlan100, [0/0], 2d13h, direct
    100.1.0.100/32, ubest/mbest: 1/0, attached
        *via 100.1.0.100, Vlan100, [190/0], 2d13h, hmm
    100.1.0.200/32, ubest/mbest: 1/0
        *via 44.44.44.44%default, [200/0], 00:28:46, bgp-65000, internal, tag 65000, segid: 50000 tunnelid: 0x2c2c2c2c
          encap: VXLAN  <remote endpoint learned via BGP>

    100.1.0.254/32, ubest/mbest: 1/0, attached
        *via 100.1.0.254, Vlan100, [0/0], 2d13h, local
    ```

=== "LEAF-2"

    ```text
    leaf-2# show ip route vrf tenant-1
    IP Route Table for VRF "tenant-1"

    100.1.0.0/24, ubest/mbest: 1/0, attached
        *via 100.1.0.254, Vlan200, [0/0], 2d13h, direct
    100.1.0.100/32, ubest/mbest: 1/0
        *via 33.33.33.33%default, [200/0], 00:26:35, bgp-65000, internal, tag 65000, segid: 50000 tunnelid: 0x21212121
          encap: VXLAN  <remote endpoint learned via BGP>

    100.1.0.200/32, ubest/mbest: 1/0, attached
        *via 100.1.0.200, Vlan200, [190/0], 2d13h, hmm
    100.1.0.254/32, ubest/mbest: 1/0, attached
        *via 100.1.0.254, Vlan200, [0/0], 2d13h, local
    ```

### Verify the BGP EVPN Table

The BGP table on each leaf shows that each leaf successfully advertised and learned Type-2 (MAC/IP) routes and Type-5 (IP prefix) routes over the EVPN control plane.

=== "LEAF-1"

    ```text
    leaf-1# show bgp l2vpn evpn
    BGP routing table information for VRF default, address family L2VPN EVPN
    BGP table version is 30, Local Router ID is 3.3.3.3
    Status: s-suppressed, x-deleted, S-stale, d-dampened, h-history, *-valid, >-best
    Path type: i-internal, e-external, c-confed, l-local, a-aggregate, r-redist, I-injected
    Origin codes: i - IGP, e - EGP, ? - incomplete, | - multipath, & - backup, 2 - best2

       Network            Next Hop            Metric     LocPrf         Weight Path
    Route Distinguisher: 3.3.3.3:32867    (L2VNI 1000)
    *>i[2]:[0]:[0]:[48]:[00ee.abd0.9197]:[0]:[0.0.0.0]/216
                          44.44.44.44                       100               0 i
    *>l[2]:[0]:[0]:[48]:[10b3.d6cb.77e7]:[0]:[0.0.0.0]/216
                          33.33.33.33                       100          32768 i
    *>i[2]:[0]:[0]:[48]:[00ee.abd0.9197]:[32]:[100.1.0.200]/272
                          44.44.44.44                       100               0 i  <remote endpoint from leaf-2>
    *>l[2]:[0]:[0]:[48]:[10b3.d6cb.77e7]:[32]:[100.1.0.100]/272
                          33.33.33.33                       100          32768 i  <local endpoint>

    Route Distinguisher: 4.4.4.4:32967
    * i[2]:[0]:[0]:[48]:[00ee.abd0.9197]:[0]:[0.0.0.0]/216
                          44.44.44.44                       100               0 i
    *>i                   44.44.44.44                       100               0 i
    *>i[2]:[0]:[0]:[48]:[00ee.abd0.9197]:[32]:[100.1.0.200]/272
                          44.44.44.44                       100               0 i
    * i                   44.44.44.44                       100               0 i

    Route Distinguisher: 3.3.3.3:4    (L3VNI 50000)
    *>i[2]:[0]:[0]:[48]:[00ee.abd0.9197]:[32]:[100.1.0.200]/272
                          44.44.44.44                       100               0 i  <remote endpoint from leaf-2>
    *>l[5]:[0]:[0]:[24]:[100.1.0.0]/224
                          33.33.33.33              0        100          32768 ?
    ```

=== "LEAF-2"

    ```text
    leaf-2# show bgp l2vpn evpn
    BGP routing table information for VRF default, address family L2VPN EVPN
    BGP table version is 30, Local Router ID is 4.4.4.4
    Status: s-suppressed, x-deleted, S-stale, d-dampened, h-history, *-valid, >-best
    Path type: i-internal, e-external, c-confed, l-local, a-aggregate, r-redist, I-injected
    Origin codes: i - IGP, e - EGP, ? - incomplete, | - multipath, & - backup, 2 - best2

       Network            Next Hop              Metric      LocPrf      Weight Path
    Route Distinguisher: 3.3.3.3:4
    *>i[5]:[0]:[0]:[24]:[100.1.0.0]/224
                          33.33.33.33                0         100            0 ?
    * i                   33.33.33.33                0         100            0 ?
    *>i[5]:[0]:[0]:[24]:[200.2.0.0]/224
                          33.33.33.33                0         100            0 ?
    * i                   33.33.33.33                 0         100           0 ?

    Route Distinguisher: 3.3.3.3:32867
    * i[2]:[0]:[0]:[48]:[10b3.d6cb.77e7]:[0]:[0.0.0.0]/216
                          33.33.33.33                       100               0 i
    *>i                   33.33.33.33                       100               0 i
    *>i[2]:[0]:[0]:[48]:[10b3.d6cb.77e7]:[32]:[100.1.0.100]/272
                          33.33.33.33                       100               0 i
    * i                   33.33.33.33                       100               0 i

    Route Distinguisher: 4.4.4.4:32967    (L2VNI 1000)
    *>l[2]:[0]:[0]:[48]:[00ee.abd0.9197]:[0]:[0.0.0.0]/216
                          44.44.44.44                       100           32768 i
    *>i[2]:[0]:[0]:[48]:[10b3.d6cb.77e7]:[0]:[0.0.0.0]/216
                          33.33.33.33                       100               0 i
    *>l[2]:[0]:[0]:[48]:[00ee.abd0.9197]:[32]:[100.1.0.200]/272
                          44.44.44.44                       100           32768 i
    *>i[2]:[0]:[0]:[48]:[10b3.d6cb.77e7]:[32]:[100.1.0.100]/272
                          33.33.33.33                       100               0 i  <remote endpoint from leaf-1>

    Route Distinguisher: 4.4.4.4:4    (L3VNI 50000)
    *>i[2]:[0]:[0]:[48]:[10b3.d6cb.77e7]:[32]:[100.1.0.100]/272
                          33.33.33.33                       100               0 i
    *>i[5]:[0]:[0]:[24]:[100.1.0.0]/224
                          33.33.33.33              0        100               0 ?
    ```

Verify the Layer 2 routing table for EVPN. The table displays how the MAC address of an endpoint was learned, the next-hop IP address, and the VNI tag.

=== "LEAF-1"

    ```text
    leaf-1# show l2route evpn mac all
    Flags -(Rmac):Router MAC (Stt):Static (L):Local (R):Remote
    (Dup):Duplicate (Spl):Split (Rcv):Recv (AD):Auto-Delete (D):Del Pending
    (S):Stale (C):Clear, (Ps):Peer Sync (O):Re-Originated (Nho):NH-Override
    (Asy):Asymmetric (Gw):Gateway
    (Bh):Blackhole, (Dum):Dummy
    (Pf):Permanently-Frozen, (Orp): Orphan
    (PipOrp): Directly connected Orphan to PIP based vPC BGW
    (PipPeerOrp): Orphan connected to peer of PIP based vPC BGW
    Topology    Mac Address    Prod   Flags              Seq No     Next-Hops
    ----------- -------------- ------ ------------------ ---------- -----------------------------------------------------
    100         00ee.abd0.9197 BGP    SplRcv             0          44.44.44.44 (Label: 1000)
    100         10b3.d6cb.77e7 Local L,                  0          Eth1/33
    8193        3488.1815.5425 VXLAN Rmac,               0          44.44.44.44
    ```

=== "LEAF-2"

    ```text
    leaf-2# show l2route evpn mac all
    Flags -(Rmac):Router MAC (Stt):Static (L):Local (R):Remote
    (Dup):Duplicate (Spl):Split (Rcv):Recv (AD):Auto-Delete (D):Del Pending
    (S):Stale (C):Clear, (Ps):Peer Sync (O):Re-Originated (Nho):NH-Override
    (Asy):Asymmetric (Gw):Gateway
    (Bh):Blackhole, (Dum):Dummy
    (Pf):Permanently-Frozen, (Orp): Orphan
    (PipOrp): Directly connected Orphan to PIP based vPC BGW
    (PipPeerOrp): Orphan connected to peer of PIP based vPC BGW
    Topology    Mac Address    Prod   Flags              Seq No     Next-Hops
    ----------- -------------- ------ ------------------ ---------- -----------------------------------------------------
    200          00ee.abd0.9197 Local     L,                    0          Eth1/34
    200          10b3.d6cb.77e7 BGP       SplRcv                0          33.33.33.33 (Label: 1000)
    8193         3488.1815.561f VXLAN     Rmac,                 0          33.33.33.33
    ```

Display the VRF associated with an L2VNI.

=== "LEAF-1"

    ```text
    leaf-1# show bgp evi 1000
    -----------------------------------------------
      L2VNI ID                     : 1000 (L2-1000)
      RD                           : 3.3.3.3:32867
      Prefixes (local/total)       : 2/4
      Created                      : Oct 6 16:32:41.058384
      Last Oper Up/Down            : Oct 6 16:32:41.060408 / never
      Enabled                      : Yes
      Associated IP-VRF            : tenant-1
      Active Export RT list        :
            65000:1000
      Active Import RT list        :
            65000:1000
    ```

=== "LEAF-2"

    ```text
    leaf-2# show bgp evi 1000
    -----------------------------------------------
      L2VNI ID                     : 1000 (L2-1000)
      RD                           : 4.4.4.4:32967
      Prefixes (local/total)       : 2/4
      Created                      : Oct 6 16:28:48.924753
      Last Oper Up/Down            : Oct 6 16:28:48.956189 / never
      Enabled                      : Yes
      Associated IP-VRF            : tenant-1
      Active Export RT list        :
            65000:1000
      Active Import RT list        :
            65000:1000
    ```

### Verify End-to-End Reachability

The hosts can successfully ping each other.

=== "Server-1"

    ```text
    PING 100.1.0.200 (100.1.0.200) from 100.1.0.100: 56 data bytes
    64 bytes from 100.1.0.200: icmp_seq=0 ttl=254 time=1.351 ms
    64 bytes from 100.1.0.200: icmp_seq=1 ttl=254 time=0.865 ms
    64 bytes from 100.1.0.200: icmp_seq=2 ttl=254 time=0.85 ms
    64 bytes from 100.1.0.200: icmp_seq=3 ttl=254 time=0.773 ms
    64 bytes from 100.1.0.200: icmp_seq=4 ttl=254 time=0.977 ms

    --- 100.1.0.200 ping statistics ---
    5 packets transmitted, 5 packets received, 0.00% packet loss
    round-trip min/avg/max = 0.773/0.963/1.351 ms
    ```

=== "Server-2"

    ```text
    PING 100.1.0.100 (100.1.0.100) from 100.1.0.200: 56 data bytes
    64 bytes from 100.1.0.100: icmp_seq=0 ttl=254 time=1.24 ms
    64 bytes from 100.1.0.100: icmp_seq=1 ttl=254 time=0.86 ms
    64 bytes from 100.1.0.100: icmp_seq=2 ttl=254 time=0.866 ms
    64 bytes from 100.1.0.100: icmp_seq=3 ttl=254 time=0.83 ms
    64 bytes from 100.1.0.100: icmp_seq=4 ttl=254 time=0.834 ms

    --- 100.1.0.100 ping statistics ---
    5 packets transmitted, 5 packets received, 0.00% packet loss
    round-trip min/avg/max = 0.83/0.926/1.24 ms
    ```

!!! success "Checkpoint"
    Both servers should ping each other with 0% packet loss over the L2 VNI before moving to the packet-walk analysis.

??? info "Packet walk: Server-1 to Server-2 (intra-VNI)"

    From a packet-walk point of view:

    1. Server-1 (100.1.0.100) initiates communication to Server-2 (100.1.0.200).
    2. As this is the first time the servers communicate, Server-1 sends an ARP request, which is a broadcast packet.

    Packet on the Ethernet segment between the leaf and Server-1:

    ![ARP request on the local Ethernet segment](../assets/vxlan-single-site-cli/img-033.png)

    This original Ethernet frame is encapsulated with a VXLAN header so it can be sent to the other leaf switches with hosts in the same VNI segment. From the packet, note the additional headers:

    ![VXLAN, UDP, and outer IP headers](../assets/vxlan-single-site-cli/img-034.png)

    1. The VXLAN header shows the VXLAN network ID (VNI) — 1000.
    2. A UDP packet with a random source port and the well-known VXLAN destination port 4789.
    3. An outer IP header that lets the packet traverse the VXLAN fabric. This IPv4 packet has a source IP address (33.33.33.33) — the nve1/loopback1 IP address of Leaf-1 — and a destination IP address of 239.0.0.1, the multicast group address associated with VNI 1000. All multi-destination packets for a particular segment in a VXLAN fabric are destined to the defined multicast group address.

    When Server-2 is identified as being located at Leaf-2, Leaf-2 encapsulates the reply packet with the outer headers (VXLAN, UDP, outer IP, and outer MAC):

    ![Leaf-2 encapsulating the ARP reply](../assets/vxlan-single-site-cli/img-036.png)

    In the outer IP header, the source IP is the nve1/loopback1 IP address (44.44.44.44) of Leaf-2, and the destination IP is the nve1/loopback1 IP address of Leaf-1 (33.33.33.33). This shows that a tunnel of communication is now established between Leaf-1 and Leaf-2, since an ARP reply is a unicast packet.

    The ARP payload confirms that the target MAC (Server-2's MAC address) is resolved.

    ![ARP reply payload showing the resolved target MAC](../assets/vxlan-single-site-cli/img-037.png)

    Expanded packet headers:

    ![Expanded VXLAN packet headers](../assets/vxlan-single-site-cli/img-039.png)

    ICMP between the two servers is achieved:

    ![ICMP exchange between Server-1 and Server-2](../assets/vxlan-single-site-cli/img-040.png)

    Overall, the packet capture confirms successful VXLAN encapsulation of Layer 2 traffic within an IP/UDP/VXLAN header. The inner ARP request from source `10b3.d6cb.77e7` (IP 100.1.0.100) to target 100.1.0.200 is encapsulated by the VTEP with source IP 33.33.33.33 and destination IP 44.44.44.44. The VXLAN header indicates VNI 1000, corresponding to the L2VNI used for the tenant segment. This verifies that the leaf switch correctly encapsulates local Layer 2 frames into VXLAN packets for transport across the underlay network, enabling Layer 2 adjacency between remote endpoints.

## Layer 3 Communication

![Layer 3 communication topology](../assets/vxlan-single-site-cli/img-042.png)

To achieve Layer 3 communication, additional configuration is added. An additional server (Server-3) in a different L2 segment (VNI 2000) with local VLAN 101 is added on Leaf-1.

=== "LEAF-1"

    ```text
    vlan 101
      vn-segment 2000
    !
    interface Vlan101
      no shutdown
      vrf member tenant-1
      ip address 200.2.0.254/24
      fabric forwarding mode anycast-gateway
    !
    interface nve1
      no shutdown
      member vni 2000
        mcast-group 239.0.0.1
    ```

### Verify the New SVI and VNI

=== "LEAF-1"

    ```text
    leaf-1# show ip interface brief vrf tenant-1
    IP Interface Status for VRF "tenant-1"(4)
    Interface            IP Address      Interface Status
    Vlan100              100.1.0.254     protocol-up/link-up/admin-up
    Vlan101              200.2.0.254     protocol-up/link-up/admin-up
    Vni50000             forward-enabled protocol-up/link-up/admin-up
    ```

    ```text
    leaf-1# show nve vni
    Codes: CP - Control Plane        DP - Data Plane
           UC - Unconfigured         SA - Suppress ARP
           S-ND - Suppress ND
           SU - Suppress Unknown Unicast
           Xconn - Crossconnect
           MS-IR - Multisite Ingress Replication
           HYB - Hybrid IRB mode

    Interface VNI      Multicast-group   State Mode Type [BD/VRF]      Flags
    --------- -------- ----------------- ----- ---- ------------------ -----
    nve1      1000     239.0.0.1         Up    CP   L2 [100]
    nve1      2000     239.0.0.1         Up    CP   L2 [101]
    nve1      50000    n/a               Up    CP   L3 [tenant-1]
    ```

Display the VRF associated with each L2VNI.

=== "LEAF-1"

    ```text
    leaf-1# show bgp evi 1000
    -----------------------------------------------
      L2VNI ID                     : 1000 (L2-1000)
      RD                           : 3.3.3.3:32867
      Prefixes (local/total)       : 2/4
      Created                      : Oct 6 16:32:41.058384
      Last Oper Up/Down            : Oct 6 16:32:41.060408 / never
      Enabled                      : Yes
      Associated IP-VRF            : tenant-1
      Active Export RT list        :
            65000:1000
      Active Import RT list        :
            65000:1000

    leaf-1# show bgp evi 2000
    -----------------------------------------------
      L2VNI ID                     : 2000 (L2-2000)
      RD                           : 3.3.3.3:32868
      Prefixes (local/total)       : 2/2
      Created                      : Oct 6 16:32:41.060528
      Last Oper Up/Down            : Oct 6 16:32:41.060627 / never
      Enabled                      : Yes
      Associated IP-VRF            : tenant-1
      Active Export RT list        :
            65000:2000
      Active Import RT list        :
            65000:2000
    ```

=== "LEAF-2"

    ```text
    leaf-2# show bgp evi 1000
    -----------------------------------------------
      L2VNI ID                     : 1000 (L2-1000)
      RD                           : 4.4.4.4:32967
      Prefixes (local/total)       : 2/4
      Created                      : Oct 6 16:28:48.924753
      Last Oper Up/Down            : Oct 6 16:28:48.956189 / never
      Enabled                      : Yes
      Associated IP-VRF            : tenant-1
      Active Export RT list        :
            65000:1000
      Active Import RT list        :
            65000:1000
    ```

### Verify Local Endpoint Learning

=== "LEAF-1"

    ```text
    leaf-1# show mac address-table dynamic
    Legend:
            * - primary entry, G - Gateway MAC, (R) - Routed MAC, O - Overlay MAC
            age - seconds since last seen,+ - primary entry using vPC Peer-Link,
            (T) - True, (F) - False, C - ControlPlane MAC, ~ - vsan
        VLAN     MAC Address      Type      age     Secure NTFY Ports
    ---------+-----------------+--------+---------+------+----+------------------
    C 100      00ee.abd0.9197   dynamic 0          F      F    nve1(44.44.44.44)
    * 100      10b3.d6cb.77e7   dynamic 0          F      F    Eth1/33
    * 101      00ee.abd0.3333   dynamic 0          F      F    Eth1/34
    ```

### Verify the Routing Table (Inter-VNI)

=== "LEAF-1"

    ```text
    leaf-1# show ip route vrf tenant-1
    IP Route Table for VRF "tenant-1"
    '*' denotes best ucast next-hop
    '**' denotes best mcast next-hop
    '[x/y]' denotes [preference/metric]
    '%<string>' in via output denotes VRF <string>

    100.1.0.0/24, ubest/mbest: 1/0, attached
        *via 100.1.0.254, Vlan100, [0/0], 2d17h, direct
    100.1.0.100/32, ubest/mbest: 1/0, attached
        *via 100.1.0.100, Vlan100, [190/0], 2d17h, hmm
    100.1.0.200/32, ubest/mbest: 1/0
        *via 44.44.44.44%default, [200/0], 04:17:36, bgp-65000, internal, tag 65000, segid: 50000 tunnelid: 0x2c2c2c2c
          encap: VXLAN
    100.1.0.254/32, ubest/mbest: 1/0, attached
        *via 100.1.0.254, Vlan100, [0/0], 2d17h, local
    200.2.0.0/24, ubest/mbest: 1/0, attached          <new subnet is now present in the routing table>
        *via 200.2.0.254, Vlan101, [0/0], 00:09:50, direct
    200.2.0.200/32, ubest/mbest: 1/0, attached
        *via 200.2.0.200, Vlan101, [190/0], 00:03:32, hmm
    200.2.0.254/32, ubest/mbest: 1/0, attached
        *via 200.2.0.254, Vlan101, [0/0], 00:09:50, local
    ```

=== "LEAF-2"

    ```text
    leaf-2# show ip route vrf tenant-1
    IP Route Table for VRF "tenant-1"
    '*' denotes best ucast next-hop
    '**' denotes best mcast next-hop
    '[x/y]' denotes [preference/metric]
    '%<string>' in via output denotes VRF <string>

    100.1.0.0/24, ubest/mbest: 1/0, attached
        *via 100.1.0.254, Vlan200, [0/0], 2d17h, direct
    100.1.0.100/32, ubest/mbest: 1/0
        *via 33.33.33.33%default, [200/0], 04:18:10, bgp-65000, internal, tag 65000, segid: 50000 tunnelid: 0x21212121
          encap: VXLAN
    100.1.0.200/32, ubest/mbest: 1/0, attached
        *via 100.1.0.200, Vlan200, [190/0], 2d17h, hmm
    100.1.0.254/32, ubest/mbest: 1/0, attached
        *via 100.1.0.254, Vlan200, [0/0], 2d17h, local
    200.2.0.0/24, ubest/mbest: 1/0
        *via 33.33.33.33%default, [200/0], 00:09:47, bgp-65000, internal, tag 65000, segid: 50000 tunnelid: 0x21212121
          encap: VXLAN
    200.2.0.200/32, ubest/mbest: 1/0
        *via 33.33.33.33%default, [200/0], 1d01h, bgp-65000, internal, tag 65000, segid: 50000 tunnelid: 0x21212121
          encap: VXLAN
    ```

### Verify the BGP EVPN Table (Inter-VNI)

=== "LEAF-1"

    ```text
    leaf-1# show bgp l2vpn evpn
    BGP routing table information for VRF default, address family L2VPN EVPN
    BGP table version is 38, Local Router ID is 3.3.3.3
    Status: s-suppressed, x-deleted, S-stale, d-dampened, h-history, *-valid, >-best
    Path type: i-internal, e-external, c-confed, l-local, a-aggregate, r-redist, I-injected
    Origin codes: i - IGP, e - EGP, ? - incomplete, | - multipath, & - backup, 2 - best2

       Network            Next Hop            Metric     LocPrf              Weight Path
    Route Distinguisher: 3.3.3.3:32867    (L2VNI 1000)
    *>i[2]:[0]:[0]:[48]:[00ee.abd0.9197]:[0]:[0.0.0.0]/216
                          44.44.44.44                       100                   0 i
    *>l[2]:[0]:[0]:[48]:[10b3.d6cb.77e7]:[0]:[0.0.0.0]/216
                          33.33.33.33                       100               32768 i
    *>i[2]:[0]:[0]:[48]:[00ee.abd0.9197]:[32]:[100.1.0.200]/272
                          44.44.44.44                       100                   0 i
    *>l[2]:[0]:[0]:[48]:[10b3.d6cb.77e7]:[32]:[100.1.0.100]/272
                          33.33.33.33                       100               32768 i

    Route Distinguisher: 3.3.3.3:32868    (L2VNI 2000)
    *>l[2]:[0]:[0]:[48]:[00ee.abd0.3333]:[0]:[0.0.0.0]/216
                          33.33.33.33                       100               32768 i
    *>l[2]:[0]:[0]:[48]:[00ee.abd0.3333]:[32]:[200.2.0.200]/272
                          33.33.33.33                       100               32768 i

    Route Distinguisher: 4.4.4.4:32967
    * i[2]:[0]:[0]:[48]:[00ee.abd0.9197]:[0]:[0.0.0.0]/216
                          44.44.44.44                       100                 0 i
    *>i                   44.44.44.44                       100                 0 i
    *>i[2]:[0]:[0]:[48]:[00ee.abd0.9197]:[32]:[100.1.0.200]/272
                          44.44.44.44                       100                 0 i
    * i                   44.44.44.44                       100                 0 i

    Route Distinguisher: 3.3.3.3:4    (L3VNI 50000)
    *>i[2]:[0]:[0]:[48]:[00ee.abd0.9197]:[32]:[100.1.0.200]/272
                          44.44.44.44                       100                 0 i
    * i[5]:[0]:[0]:[24]:[100.1.0.0]/224
                          44.44.44.44               0       100                 0 ?
    *>l                   33.33.33.33              0        100             32768 ?
    *>l[5]:[0]:[0]:[24]:[200.2.0.0]/224
                          33.33.33.33               0       100             32768 ?
    ```

=== "LEAF-2"

    ```text
    leaf-2# show bgp l2vpn evpn
    BGP routing table information for VRF default, address family L2VPN EVPN
    BGP table version is 56, Local Router ID is 4.4.4.4
    Status: s-suppressed, x-deleted, S-stale, d-dampened, h-history, *-valid, >-best
    Path type: i-internal, e-external, c-confed, l-local, a-aggregate, r-redist, I-injected
    Origin codes: i - IGP, e - EGP, ? - incomplete, | - multipath, & - backup, 2 - best2

       Network            Next Hop                 Metric      LocPrf      Weight Path
    Route Distinguisher: 3.3.3.3:4
    *>i[5]:[0]:[0]:[24]:[100.1.0.0]/224
                          33.33.33.33                   0         100           0 ?
    * i                   33.33.33.33                   0         100           0 ?
    *>i[5]:[0]:[0]:[24]:[200.2.0.0]/224
                          33.33.33.33                   0         100           0 ?
    * i                   33.33.33.33                   0         100           0 ?

    Route Distinguisher: 3.3.3.3:32867
    * i[2]:[0]:[0]:[48]:[10b3.d6cb.77e7]:[0]:[0.0.0.0]/216
                          33.33.33.33                       100                 0 i
    *>i                   33.33.33.33                       100                 0 i
    *>i[2]:[0]:[0]:[48]:[10b3.d6cb.77e7]:[32]:[100.1.0.100]/272
                          33.33.33.33                       100                 0 i
    * i                   33.33.33.33                       100                 0 i

    Route Distinguisher: 3.3.3.3:32868
    *>i[2]:[0]:[0]:[48]:[00ee.abd0.3333]:[32]:[200.2.0.200]/272
                          33.33.33.33                       100                 0 i
    * i                   33.33.33.33                       100                 0 i

    Route Distinguisher: 4.4.4.4:32967    (L2VNI 1000)
    *>l[2]:[0]:[0]:[48]:[00ee.abd0.9197]:[0]:[0.0.0.0]/216
                          44.44.44.44                       100             32768 i
    *>i[2]:[0]:[0]:[48]:[10b3.d6cb.77e7]:[0]:[0.0.0.0]/216
                          33.33.33.33                       100                 0 i
    *>l[2]:[0]:[0]:[48]:[00ee.abd0.9197]:[32]:[100.1.0.200]/272
                          44.44.44.44                       100             32768 i
    *>i[2]:[0]:[0]:[48]:[10b3.d6cb.77e7]:[32]:[100.1.0.100]/272
                          33.33.33.33                       100                 0 i

    Route Distinguisher: 4.4.4.4:4    (L3VNI 50000)
    *>i[2]:[0]:[0]:[48]:[10b3.d6cb.77e7]:[32]:[100.1.0.100]/272
                          33.33.33.33                       100                 0 i
    *>i[2]:[0]:[0]:[48]:[00ee.abd0.3333]:[32]:[200.2.0.200]/272
                          33.33.33.33                       100                 0 i
    *>l[5]:[0]:[0]:[24]:[100.1.0.0]/224
                          44.44.44.44                      0          100           32768 ?
    * i                   33.33.33.33                      0          100               0 ?
    *>i[5]:[0]:[0]:[24]:[200.2.0.0]/224
                          33.33.33.33                      0          100              0 ?
    ```

### Verify Advertised Routes to the Route Reflectors

Verify the routes each leaf advertises to the route reflectors (spines).

=== "LEAF-1"

    ```text
    leaf-1# show bgp l2vpn evpn neig 1.1.1.1 advertised-routes
    Peer 1.1.1.1 routes for address family L2VPN EVPN:
    BGP table version is 42, Local Router ID is 3.3.3.3
    Status: s-suppressed, x-deleted, S-stale, d-dampened, h-history, *-valid, >-best
    Path type: i-internal, e-external, c-confed, l-local, a-aggregate, r-redist, I-injected
    Origin codes: i - IGP, e - EGP, ? - incomplete, | - multipath, & - backup, 2 - best2

       Network            Next Hop            Metric     LocPrf                Weight Path
    Route Distinguisher: 3.3.3.3:32867    (L2VNI 1000)
    *>l[2]:[0]:[0]:[48]:[10b3.d6cb.77e7]:[0]:[0.0.0.0]/216
                          33.33.33.33                       100                     32768 i
    *>l[2]:[0]:[0]:[48]:[10b3.d6cb.77e7]:[32]:[100.1.0.100]/272
                          33.33.33.33                       100                     32768 i

    Route Distinguisher: 3.3.3.3:32868    (L2VNI 2000)
    *>l[2]:[0]:[0]:[48]:[00ee.abd0.3333]:[0]:[0.0.0.0]/216
                          33.33.33.33                       100                     32768 i
    *>l[2]:[0]:[0]:[48]:[00ee.abd0.3333]:[32]:[200.2.0.200]/272
                          33.33.33.33                       100                     32768 i

    Route Distinguisher: 4.4.4.4:4

    Route Distinguisher: 4.4.4.4:32967

    Route Distinguisher: 3.3.3.3:4    (L3VNI 50000)
    *>l[5]:[0]:[0]:[24]:[100.1.0.0]/224
                          33.33.33.33               0                 100           32768 ?
    *>l[5]:[0]:[0]:[24]:[200.2.0.0]/224
                          33.33.33.33               0                 100           32768 ?
    ```

    ```text
    leaf-1# show bgp l2vpn evpn neig 2.2.2.2 advertised-routes
    Peer 2.2.2.2 routes for address family L2VPN EVPN:
    BGP table version is 42, Local Router ID is 3.3.3.3
    Status: s-suppressed, x-deleted, S-stale, d-dampened, h-history, *-valid, >-best
    Path type: i-internal, e-external, c-confed, l-local, a-aggregate, r-redist, I-injected
    Origin codes: i - IGP, e - EGP, ? - incomplete, | - multipath, & - backup, 2 - best2

       Network            Next Hop            Metric     LocPrf                Weight Path
    Route Distinguisher: 3.3.3.3:32867    (L2VNI 1000)
    *>l[2]:[0]:[0]:[48]:[10b3.d6cb.77e7]:[0]:[0.0.0.0]/216
                          33.33.33.33                       100                     32768 i
    *>l[2]:[0]:[0]:[48]:[10b3.d6cb.77e7]:[32]:[100.1.0.100]/272
                          33.33.33.33                       100                     32768 i

    Route Distinguisher: 3.3.3.3:32868    (L2VNI 2000)
    *>l[2]:[0]:[0]:[48]:[00ee.abd0.3333]:[0]:[0.0.0.0]/216
                          33.33.33.33                       100                     32768 i
    *>l[2]:[0]:[0]:[48]:[00ee.abd0.3333]:[32]:[200.2.0.200]/272
                          33.33.33.33                       100                     32768 i

    Route Distinguisher: 4.4.4.4:4

    Route Distinguisher: 4.4.4.4:32967

    Route Distinguisher: 3.3.3.3:4    (L3VNI 50000)
    *>l[5]:[0]:[0]:[24]:[100.1.0.0]/224
                          33.33.33.33               0             100       32768 ?
    *>l[5]:[0]:[0]:[24]:[200.2.0.0]/224
                          33.33.33.33               0             100       32768 ?
    ```

=== "LEAF-2"

    ```text
    leaf-2# show bgp l2vpn evpn neig 1.1.1.1 advertised-routes
    Peer 1.1.1.1 routes for address family L2VPN EVPN:
    BGP table version is 57, Local Router ID is 4.4.4.4
    Status: s-suppressed, x-deleted, S-stale, d-dampened, h-history, *-valid, >-best
    Path type: i-internal, e-external, c-confed, l-local, a-aggregate, r-redist, I-injected
    Origin codes: i - IGP, e - EGP, ? - incomplete, | - multipath, & - backup, 2 - best2

       Network            Next Hop                 Metric      LocPrf      Weight Path
    Route Distinguisher: 3.3.3.3:4

    Route Distinguisher: 3.3.3.3:32867

    Route Distinguisher: 3.3.3.3:32868

    Route Distinguisher: 4.4.4.4:32967    (L2VNI 1000)
    *>l[2]:[0]:[0]:[48]:[00ee.abd0.9197]:[0]:[0.0.0.0]/216
                          44.44.44.44                       100             32768 i
    *>l[2]:[0]:[0]:[48]:[00ee.abd0.9197]:[32]:[100.1.0.200]/272
                          44.44.44.44                       100             32768 i

    Route Distinguisher: 4.4.4.4:4    (L3VNI 50000)
    *>l[5]:[0]:[0]:[24]:[100.1.0.0]/224
                          44.44.44.44               0             100       32768
    ```

    ```text
    leaf-2# show bgp l2vpn evpn neig 2.2.2.2 advertised-routes
    Peer 2.2.2.2 routes for address family L2VPN EVPN:
    BGP table version is 57, Local Router ID is 4.4.4.4
    Status: s-suppressed, x-deleted, S-stale, d-dampened, h-history, *-valid, >-best
    Path type: i-internal, e-external, c-confed, l-local, a-aggregate, r-redist, I-injected
    Origin codes: i - IGP, e - EGP, ? - incomplete, | - multipath, & - backup, 2 - best2

       Network            Next Hop                 Metric      LocPrf      Weight Path
    Route Distinguisher: 3.3.3.3:4

    Route Distinguisher: 3.3.3.3:32867

    Route Distinguisher: 3.3.3.3:32868

    Route Distinguisher: 4.4.4.4:32967    (L2VNI 1000)
    *>l[2]:[0]:[0]:[48]:[00ee.abd0.9197]:[0]:[0.0.0.0]/216
                          44.44.44.44                       100             32768 i
    *>l[2]:[0]:[0]:[48]:[00ee.abd0.9197]:[32]:[100.1.0.200]/272
                          44.44.44.44                       100             32768 i

    Route Distinguisher: 4.4.4.4:4    (L3VNI 50000)
    *>l[5]:[0]:[0]:[24]:[100.1.0.0]/224
                          44.44.44.44               0             100       32768 ?
    ```

### Verify MAC-IP Routes

=== "LEAF-1"

    ```text
    leaf-1# show l2route evpn mac-ip all
    Flags -(Rmac):Router MAC (Stt):Static (L):Local (R):Remote
    (Dup):Duplicate (Spl):Split (Rcv):Recv(D):Del Pending (S):Stale (C):Clear
    (Ps):Peer Sync (Ro):Re-Originated (Orp):Orphan (Asy):Asymmetric (Gw):Gateway
    (Bh):Blackhole
    (Piporp): Directly connected Orphan to PIP based vPC BGW
    (Pipporp): Orphan connected to peer of PIP based vPC BGW
    Topology    Mac Address    Host IP                                 Prod   Flags              Seq No     Next-Hops
    ----------- -------------- --------------------------------------- ------ ----------------- ---------- ------------------------------
    100         10b3.d6cb.77e7 100.1.0.100                             HMM    L,                 0         Local
    100         00ee.abd0.9197 100.1.0.200                             BGP    --                 0         44.44.44.44 (Label: 1000)
    101         00ee.abd0.3333 200.2.0.200                             HMM    L,                 0         Local
    !
    leaf-1# show l2route evpn mac-ip all detail
    Topology    Mac Address    Host IP                                 Prod   Flags              Seq No     Next-Hops
    ----------- -------------- --------------------------------------- ------ ----------------- ---------- ------------------------------
    100         10b3.d6cb.77e7 100.1.0.100                             HMM    L,                 0         Local
                L3-Info: 50000
                Sent To: BGP
    100         00ee.abd0.9197 100.1.0.200                             BGP    --                 0         44.44.44.44 (Label: 1000)
                encap-type:1
    101         00ee.abd0.3333 200.2.0.200                             HMM    L,                 0         Local
                L3-Info: 50000
                Sent To: BGP
    ```

=== "LEAF-2"

    ```text
    leaf-2# show l2route evpn mac-ip all
    Flags -(Rmac):Router MAC (Stt):Static (L):Local (R):Remote
    (Dup):Duplicate (Spl):Split (Rcv):Recv(D):Del Pending (S):Stale (C):Clear
    (Ps):Peer Sync (Ro):Re-Originated (Orp):Orphan (Asy):Asymmetric (Gw):Gateway
    (Bh):Blackhole
    (Piporp): Directly connected Orphan to PIP based vPC BGW
    (Pipporp): Orphan connected to peer of PIP based vPC BGW
    Topology    Mac Address    Host IP                                 Prod   Flags              Seq No     Next-Hops
    ----------- -------------- --------------------------------------- ------ ----------------- ---------- ------------------------------
    200         10b3.d6cb.77e7 100.1.0.100                             BGP    --                 0         33.33.33.33 (Label: 1000)
    200         00ee.abd0.9197 100.1.0.200                             HMM    L,                 0         Local
    !
    leaf-2# show l2route evpn mac-ip all detail
    Flags -(Rmac):Router MAC (Stt):Static (L):Local (R):Remote
    (Dup):Duplicate (Spl):Split (Rcv):Recv(D):Del Pending (S):Stale (C):Clear
    (Ps):Peer Sync (Ro):Re-Originated (Orp):Orphan (Asy):Asymmetric (Gw):Gateway
    (Bh):Blackhole
    (Piporp): Directly connected Orphan to PIP based vPC BGW
    (Pipporp): Orphan connected to peer of PIP based vPC BGW
    Topology    Mac Address    Host IP                                 Prod   Flags              Seq No     Next-Hops
    ----------- -------------- --------------------------------------- ------ ----------------- ---------- ------------------------------
    200         10b3.d6cb.77e7 100.1.0.100                             BGP    --                 0         33.33.33.33 (Label: 1000)
                encap-type:1
    200         00ee.abd0.9197 100.1.0.200                             HMM    L,                 0         Local
                L3-Info: 50000
                Sent To: BGP
    ```

### Verify End-to-End Reachability (Inter-VNI)

The hosts can successfully ping each other across L2 segments (Server-2 on VNI 1000, Server-3 on VNI 2000).

=== "Server-2"

    ```text
    PING 200.2.0.200 (200.2.0.200) from 100.1.0.200: 56 data bytes
    64 bytes from 200.2.0.200: icmp_seq=0 ttl=254 time=1.386 ms
    64 bytes from 200.2.0.200: icmp_seq=1 ttl=254 time=0.861 ms
    64 bytes from 200.2.0.200: icmp_seq=2 ttl=254 time=0.886 ms
    64 bytes from 200.2.0.200: icmp_seq=3 ttl=254 time=0.913 ms
    64 bytes from 200.2.0.200: icmp_seq=4 ttl=254 time=0.802 ms

    --- 200.2.0.200 ping statistics ---
    5 packets transmitted, 5 packets received, 0.00% packet loss
    round-trip min/avg/max = 0.802/0.969/1.386 ms
    ```

=== "Server-3"

    ```text
    PING 100.1.0.200 (100.1.0.200) from 200.2.0.200: 56 data bytes
    64 bytes from 100.1.0.200: icmp_seq=0 ttl=252 time=1.264 ms
    64 bytes from 100.1.0.200: icmp_seq=1 ttl=252 time=1.084 ms
    64 bytes from 100.1.0.200: icmp_seq=2 ttl=252 time=1.121 ms
    64 bytes from 100.1.0.200: icmp_seq=3 ttl=252 time=0.97 ms
    64 bytes from 100.1.0.200: icmp_seq=4 ttl=252 time=0.876 ms

    --- 100.1.0.200 ping statistics ---
    5 packets transmitted, 5 packets received, 0.00% packet loss
    round-trip min/avg/max = 0.876/1.063/1.264 ms
    ```

!!! success "Checkpoint"
    Server-2 and Server-3 — in different L2 VNIs — should ping each other with 0% packet loss, confirming inter-VNI routing through the L3 VNI.

From a packet-encapsulation point of view, an important factor to note is that when two hosts residing in different L2 segments (VNIDs) need to communicate, the VXLAN Network Identifier used is the L3VNI — in this case, 50000.

![Inter-VNI packet encapsulation using the L3VNI](../assets/vxlan-single-site-cli/img-050.png)

## Full Device Configurations

The complete, final configuration for each device is provided below as a reference. Use it to compare against your own configuration once you have completed the guided sections above.

=== "SPINE-1"

    ```text
    hostname spine-1
    nv overlay evpn
    feature ospf
    feature bgp
    feature pim
    feature lldp
    ip pim rp-address 12.12.12.12 group-list 239.0.0.0/24
    ip pim anycast-rp 12.12.12.12 1.1.1.1
    ip pim anycast-rp 12.12.12.12 2.2.2.2
    interface Ethernet1/3
      description to leaf-2
      mtu 9216
      ip address 10.14.14.1/30
      ip ospf network point-to-point
      ip router ospf UNDERLAY area 0.0.0.0
      ip pim sparse-mode
      no shutdown
    interface Ethernet1/4
      description to leaf-1
      mtu 9216
      ip address 10.13.13.1/30
      ip ospf network point-to-point
      ip router ospf UNDERLAY area 0.0.0.0
      ip pim sparse-mode
      no shutdown
    interface loopback0
      description for-vtep-reachability
      ip address 1.1.1.1/32
      ip router ospf UNDERLAY area 0.0.0.0
      ip pim sparse-mode
    interface loopback1
      description for-mcast
      ip address 12.12.12.12/32
      ip router ospf UNDERLAY area 0.0.0.0
      ip pim sparse-mode
    router ospf UNDERLAY
    router bgp 65000
      address-family l2vpn evpn
      neighbor 3.3.3.3
        remote-as 65000
        update-source loopback0
        address-family l2vpn evpn
          send-community
          send-community extended
          route-reflector-client
      neighbor 4.4.4.4
        remote-as 65000
        update-source loopback0
        address-family l2vpn evpn
          send-community
          send-community extended
          route-reflector-client
    ```

=== "SPINE-2"

    ```text
    hostname spine-2
    nv overlay evpn
    feature ospf
    feature bgp
    feature pim
    feature lldp
    ip pim rp-address 12.12.12.12 group-list 239.0.0.0/24
    ip pim anycast-rp 12.12.12.12 1.1.1.1
    ip pim anycast-rp 12.12.12.12 2.2.2.2
    interface Ethernet1/3
      description to leaf-1
      mtu 9216
      ip address 10.23.23.1/30
      ip ospf network point-to-point
      ip router ospf UNDERLAY area 0.0.0.0
      ip pim sparse-mode
      no shutdown
    interface Ethernet1/4
      description to leaf-2
      mtu 9216
      ip address 10.24.24.1/30
      ip ospf network point-to-point
      ip router ospf UNDERLAY area 0.0.0.0
      ip pim sparse-mode
      no shutdown
    interface loopback0
      description for-vtep-reachability
      ip address 2.2.2.2/32
      ip router ospf UNDERLAY area 0.0.0.0
      ip pim sparse-mode
    interface loopback1
      description for-mcast
      ip address 12.12.12.12/32
      ip router ospf UNDERLAY area 0.0.0.0
      ip pim sparse-mode
    router ospf UNDERLAY
    router bgp 65000
      address-family l2vpn evpn
      neighbor 3.3.3.3
        remote-as 65000
        update-source loopback0
        address-family l2vpn evpn
          send-community
          send-community extended
          route-reflector-client
      neighbor 4.4.4.4
        remote-as 65000
        update-source loopback0
        address-family l2vpn evpn
          send-community
          send-community extended
          route-reflector-client
    ```

=== "LEAF-1"

    ```text
    hostname leaf-1
    nv overlay evpn
    feature ospf
    feature bgp
    feature pim
    feature interface-vlan
    feature vn-segment-vlan-based
    feature lldp
    feature nv overlay
    fabric forwarding anycast-gateway-mac 0002.0002.0002
    ip pim rp-address 12.12.12.12 group-list 239.0.0.0/24
    vlan 1,100-101
    vlan 100
      vn-segment 1000
    vlan 101
      vn-segment 2000
    route-map PERMIT-ALL permit 10
    vrf context tenant-1
      vni 50000 l3
      rd auto
      address-family ipv4 unicast
       route-target both auto
       route-target both auto evpn
    interface Vlan100
      no shutdown
      vrf member tenant-1
      ip address 100.1.0.254/24
      fabric forwarding mode anycast-gateway
    interface Vlan101
      no shutdown
      vrf member tenant-1
      ip address 200.2.0.254/24
      fabric forwarding mode anycast-gateway
    interface nve1
      no shutdown
      host-reachability protocol bgp
      source-interface loopback1
      member vni 1000
        mcast-group 239.0.0.1
      member vni 2000
        mcast-group 239.0.0.1
      member vni 50000 associate-vrf
    interface Ethernet1/3
      description to spine-2
      mtu 9216
      ip address 10.23.23.2/30
      ip ospf network point-to-point
      ip router ospf UNDERLAY area 0.0.0.0
      ip pim sparse-mode
      no shutdown
    interface Ethernet1/4
      description to spine-1
      mtu 9216
      ip address 10.13.13.2/30
      ip ospf network point-to-point
      ip router ospf UNDERLAY area 0.0.0.0
      ip pim sparse-mode
      no shutdown
    interface loopback0
      description for-vtep-reachability
      ip address 3.3.3.3/32
      ip router ospf UNDERLAY area 0.0.0.0
      ip pim sparse-mode
    interface loopback1
      description for-vni-peering
      ip address 33.33.33.33/32
      ip router ospf UNDERLAY area 0.0.0.0
      ip pim sparse-mode
    router ospf UNDERLAY
    router bgp 65000
      address-family l2vpn evpn
      neighbor 1.1.1.1
        remote-as 65000
        update-source loopback0
        address-family l2vpn evpn
        send-community
        send-community extended
      neighbor 2.2.2.2
        remote-as 65000
        update-source loopback0
        address-family l2vpn evpn
        send-community
        send-community extended
      vrf tenant-1
        address-family ipv4 unicast
        redistribute direct route-map PERMIT-ALL
    ```

=== "LEAF-2"

    ```text
    hostname leaf-2
    nv overlay evpn
    feature ospf
    feature bgp
    feature pim
    feature interface-vlan
    feature vn-segment-vlan-based
    feature lldp
    feature nv overlay
    fabric forwarding anycast-gateway-mac 0002.0002.0002
    ip pim rp-address 12.12.12.12 group-list 239.0.0.0/24
    vlan 1,200
    vlan 200
      vn-segment 1000
    route-map PERMIT-ALL permit 10
    vrf context tenant-1
      vni 50000 l3
      rd auto
      address-family ipv4 unicast
       route-target both auto
       route-target both auto evpn
    interface Vlan200
      no shutdown
      vrf member tenant-1
      ip address 100.1.0.254/24
      fabric forwarding mode anycast-gateway
    interface nve1
      no shutdown
      host-reachability protocol bgp
      source-interface loopback1
      member vni 1000
        mcast-group 239.0.0.1
      member vni 50000 associate-vrf
    interface Ethernet1/3
      description to spine-1
      mtu 9216
      ip address 10.14.14.2/30
      ip ospf network point-to-point
      ip router ospf UNDERLAY area 0.0.0.0
      ip pim sparse-mode
      no shutdown
    interface Ethernet1/4
      description to spine-2
      mtu 9216
      ip address 10.24.24.2/30
      ip ospf network point-to-point
      ip router ospf UNDERLAY area 0.0.0.0
      ip pim sparse-mode
      no shutdown
    interface loopback0
      description for-vtep-reachability
      ip address 4.4.4.4/32
      ip router ospf UNDERLAY area 0.0.0.0
      ip pim sparse-mode
    interface loopback1
      description for-vni-peering
      ip address 44.44.44.44/32
      ip router ospf UNDERLAY area 0.0.0.0
      ip pim sparse-mode
    router ospf UNDERLAY
    router bgp 65000
      address-family l2vpn evpn
      neighbor 1.1.1.1
        remote-as 65000
        update-source loopback0
        address-family l2vpn evpn
        send-community
        send-community extended
      neighbor 2.2.2.2
        remote-as 65000
        update-source loopback0
        address-family l2vpn evpn
        send-community
        send-community extended
      vrf tenant-1
        address-family ipv4 unicast
        redistribute direct route-map PERMIT-ALL
    ```

For more labs visit my GitHub repo: [https://github.com/TitusM/Cisco-Data-Center](https://github.com/TitusM/Cisco-Data-Center)

## References

- [Cisco VXLAN BGP EVPN Design and Implementation Guide](https://www.cisco.com/c/en/us/td/docs/dcn/whitepapers/cisco-vxlan-bgp-evpn-design-and-implementation-guide.html)
- [Cisco Nexus 9000 Series NX-OS VXLAN Configuration Guide, Release 10.5(x)](https://www.cisco.com/c/en/us/td/docs/dcn/nx-os/nexus9000/105x/configuration/vxlan/cisco-nexus-9000-series-nx-os-vxlan-configuration-guide-release-105x/m_overview.html)
- [Cisco Live On-Demand Library — VXLAN sessions (video 1)](https://www.ciscolive.com/on-demand/on-demand-library.html?search=VXLAN#/video/1751036939701001hVz0)
- [Cisco Live On-Demand Library — VXLAN sessions (video 2)](https://www.ciscolive.com/on-demand/on-demand-library.html?search=VXLAN#/video/1751036941693001hMFt)
