# VXLAN BGP EVPN FABRIC BRING UP USING NDFC – SINGLE SITE

![VXLAN BGP EVPN single-site NDFC topology](../assets/vxlan-single-site-ndfc/img-005.png)

For more labs visit my GitHub repo: [https://github.com/TitusM/Cisco-Data-Center](https://github.com/TitusM/Cisco-Data-Center)

!!! note
    This lab was conducted in a controlled environment. Any configurations in a production network should be implemented during a designated maintenance window. Additionally, always refer to official Cisco documentation relevant to your specific hardware and software.

## Introduction

This lab demonstrates the process of bringing up a VXLAN BGP EVPN fabric using the Cisco Nexus Dashboard Fabric Controller (NDFC). NDFC is a comprehensive management and automation solution that simplifies and accelerates the deployment of VXLAN fabrics through embedded templates aligned with Cisco’s best practices.

In addition, NDFC provides flexibility through its Freeform Configuration feature, allowing users to apply custom configurations beyond the predefined templates.

This lab walks through the end-to-end workflow of:

- Creating a VXLAN BGP EVPN fabric
- Onboarding NX-OS switches into the fabric
- Bringing up the underlay and overlay networks
- Creating networks (VNIs, VRFs)
- Attaching server interfaces to enable communication across the VXLAN fabric

!!! note
    This lab does not showcase the initial bring up of the Nexus Dashboard Fabric Controller.

## Lab Topology

![VXLAN BGP EVPN single-site NDFC lab topology](../assets/vxlan-single-site-ndfc/img-007.png)

## Deploying a VXLAN EVPN Fabric using NDFC

The first part of the deployment is to create the fabric along with required settings like the fabric BGP ASN, the IGP for the underlay, replication mode for multi-destination traffic, VTEP interfaces etc.

Login the Nexus Dashboard

![Nexus Dashboard login page](../assets/vxlan-single-site-ndfc/img-009.png)

Navigate to Manage >> Fabric >> Create Fabric

![Nexus Dashboard Fabrics create fabric action](../assets/vxlan-single-site-ndfc/img-010.png)

Create new LAN fabric

![Create new LAN fabric selection](../assets/vxlan-single-site-ndfc/img-011.png)

Select VXLAN >> Data Center VXLAN EVPN

![Data Center VXLAN EVPN fabric type selection](../assets/vxlan-single-site-ndfc/img-013.png)

On the Settings tab, choose the Advanced tab to start configuring the VXLAN fabric settings. Define the required parameters according to your environment.

![VXLAN fabric settings basic parameters](../assets/vxlan-single-site-ndfc/img-014.png)

The next tab is the Advanced Settings >> General Parameters required to define underlay parameters, route-reflectors definition and the anycast gateway.

![Advanced settings general parameters](../assets/vxlan-single-site-ndfc/img-016.png)

Notes:

1. For fabric Interface numbering there are 2 options to choose from – p2p or IP unnumbered.

![Fabric Interface Numbering p2p option](../assets/vxlan-single-site-ndfc/img-017.png)

2. The underlay subnet IP mask allows for either a /30 or /31.

![Underlay Subnet IP Mask options](../assets/vxlan-single-site-ndfc/img-018.png)

3. OSPF or ISIS are the possible IGPs that can be used for the underlay.

![Underlay Routing Protocol options](../assets/vxlan-single-site-ndfc/img-020.png)

4. A maximum of 4 route-reflectors are possible.

![Route-Reflectors options](../assets/vxlan-single-site-ndfc/img-021.png)

The next step is to configure the Replication mode and required parameters. In this lab, Multicast is used as the replication mode.

![Replication mode multicast settings](../assets/vxlan-single-site-ndfc/img-022.png)

For the replication mode – the 2 options available are multicast or ingress replication.

![Replication Mode multicast and ingress options](../assets/vxlan-single-site-ndfc/img-023.png)

Still under the Replication section, select the number of Rendezvous points (options – 2 or 4), choose the RP mode (ASM or BiDir) and the Underlay RP loopback ID.

![Rendezvous point and RP mode settings](../assets/vxlan-single-site-ndfc/img-025.png)

Select the Advanced tab and Enable the “Add Switches without Reload” option.

![Add Switches without Reload enabled](../assets/vxlan-single-site-ndfc/img-026.png)

Click on the Resources tab and define the subnets required for the underlay loopbacks, VTEP loopback, underlay IP subnet range that will be assigned to interfaces and the Underlay RP loopback IP range.

![Resources tab underlay IP ranges](../assets/vxlan-single-site-ndfc/img-027.png)

Under the same Resources tab, define the L2 VNI and L3 VNI ranges and change the VRF Lite Deployment mode from manual to back2BackAndToExternal.

![Resources tab VNI ranges and VRF Lite deployment mode](../assets/vxlan-single-site-ndfc/img-029.png)

You can enable the Auto Deploy for Peer option so that Nexus Dashboard can automate the configuration on an external device if it is an NXOS or ASR9k for VRF-Lite extension out of the VXLAN EVPN fabric.

![Auto Deploy for Peer option](../assets/vxlan-single-site-ndfc/img-030.png)

There are a lot more settings but for now this should be enough to get us started.

Click Next and Review the Summary before clicking on Submit.

![Fabric creation summary](../assets/vxlan-single-site-ndfc/img-032.png)

![Fabric advanced settings summary](../assets/vxlan-single-site-ndfc/img-033.png)

![Fabric resources summary](../assets/vxlan-single-site-ndfc/img-034.png)

![Fabric VNI ranges summary](../assets/vxlan-single-site-ndfc/img-035.png)

After Clicking Submit, the Fabric creation process starts:

![Fabric creation in progress](../assets/vxlan-single-site-ndfc/img-037.png)

The fabric was successfully created:

![Fabric successfully created](../assets/vxlan-single-site-ndfc/img-038.png)

Now it’s time to add the Switches ☺

## Adding Switches to the VXLAN Fabric

After the successful creation of the Fabric, the next step is to onboard the switches in the fabric. The Figure below shows that currently there are no switches onboarded in the VXLAN fabric.

![Empty fabric inventory](../assets/vxlan-single-site-ndfc/img-039.png)

In this lab, the switches are discovered using the mgmt0 IP address. To achieve this, minimal configuration (snippet below) was put in place on the switches.

Example:

```text
hostname <hostname>
username admin password 5 <password> role network-admin
!
interface mgmt0
  no cdp enable
  vrf member management
  ip address 198.18.xx.yy/24
!
vrf context management
  ip route 0.0.0.0/0 198.18.xx.yy
```

Under the Fabric, click on Actions >> Add Switches

![Add Switches action](../assets/vxlan-single-site-ndfc/img-041.png)

The “Add switches” window will pop up and all field should be filled in accordingly.

![Add switches seed switch details](../assets/vxlan-single-site-ndfc/img-042.png)

![Add switches seed switch details continued](../assets/vxlan-single-site-ndfc/img-043.png)

In this lab the seed IP used is the mgmt0 of Leaf-1. Through the “Max Hops” Leaf 1’s LLDP neighbors are discovered, along with their respective LLDP neighbors as well.

The user is prompted to confirm the controllers intentions to clean and onboard the switch. Any configuration exceeding the minimal required setup will be cleared.

![Warning before switch clean and import](../assets/vxlan-single-site-ndfc/img-045.png)

The switches are successfully discovered by NDFC.

![Discovered switch results](../assets/vxlan-single-site-ndfc/img-046.png)

Click on the tick box for the specific devices you want to add and click on “Add switches”.

![Switch discovery results selected](../assets/vxlan-single-site-ndfc/img-047.png)

Grab some coffee ☺

![Switch discovery in progress](../assets/vxlan-single-site-ndfc/img-049.png)

![Switch import in progress](../assets/vxlan-single-site-ndfc/img-050.png)

At this point it is observed that the switches are successfully added to the VXLAN fabric.

![Switches added to fabric](../assets/vxlan-single-site-ndfc/img-051.png)

Under the Fabric, navigate to the Inventory tab and verify that all switches are present.

The next step is to configure each switch with the correct role that is required for it to operate in the fabric. For each switch role, there is a specific deployment/configuration template for it in NDFC.

Select the tick box of a switch >> Actions >> Set role.

![Set role action](../assets/vxlan-single-site-ndfc/img-053.png)

Select Role from the options below.

![Select Role options](../assets/vxlan-single-site-ndfc/img-054.png)

Press Ok.

![Warning to recalculate and deploy](../assets/vxlan-single-site-ndfc/img-055.png)

Repeat the same procedure for the Spine, Leaf and Border Leaf.

![Set role action for additional switches](../assets/vxlan-single-site-ndfc/img-056.png)

![Set border role](../assets/vxlan-single-site-ndfc/img-058.png)

![Set spine role](../assets/vxlan-single-site-ndfc/img-059.png)

The next step is to define VPC pairing on leaf switches. In this lab Site1-L1 and Site1-L2 will be configured as vPC peers. Select one Leaf that forms part of the vPC domain >> Actions >> VPC pairing.

![VPC pairing action](../assets/vxlan-single-site-ndfc/img-060.png)

A new configuration window will show the switches that are eligible to pair with the selected switch. In this case Site1-L2 is the eligible pair so it is selected to be part of the vPC domain.

![VPC pairing eligible switch selection](../assets/vxlan-single-site-ndfc/img-061.png)

![VPC pairing confirmation](../assets/vxlan-single-site-ndfc/img-062.png)

Now it is time to deploy all configurations that are embedded in the templates to all devices. Select all devices in the Inventory >> Actions >> Recalculate and Deploy.

![Recalculate and Deploy action](../assets/vxlan-single-site-ndfc/img-064.png)

NDFC will perform a recalculation process to determine the configuration lines that will be added to each switch.

![Recalculating config on switches 5 percent](../assets/vxlan-single-site-ndfc/img-065.png)

![Recalculating config on switches 10 percent](../assets/vxlan-single-site-ndfc/img-066.png)

![Recalculating config on switches 40 percent](../assets/vxlan-single-site-ndfc/img-067.png)

The image below displays the “Pending Config” for each device. If you want to see the configuration that will be pushed, you can line on either Lines in the Pending Config column and a new window with the specific configuration(dry run) will show.

![Pending config for each switch](../assets/vxlan-single-site-ndfc/img-068.png)

The deployment process will start.

![Deployment in progress](../assets/vxlan-single-site-ndfc/img-070.png)

Deployment completed successfully.

![Deployment completed successfully](../assets/vxlan-single-site-ndfc/img-071.png)

From this point, we can perform verifications as the VXLAN fabric is now up and running.

Under the Fabric, click on “View in topology” to view the fabric’s topology.

![View in topology button](../assets/vxlan-single-site-ndfc/img-072.png)

![Fabric topology view selector](../assets/vxlan-single-site-ndfc/img-073.png)

![Fabric topology view](../assets/vxlan-single-site-ndfc/img-074.png)

Navigate back to the Fabric’s Overview page. This page gives details regarding the fabric’s health, anomalies summary etc. This show cases NDFC’s capability for Day-2 Operations. Having visibility to your network is not a luxury, it is a necessity.

![Fabric overview with health and anomalies](../assets/vxlan-single-site-ndfc/img-076.png)

The image below shows a high count of anomalies in the fabric. Let’s drill down to see what these anomalies are.

![Fabric overview anomaly drilldown](../assets/vxlan-single-site-ndfc/img-077.png)

Click on the Anomalies tab. This tab shows that the anomalies being flagged are related to “interface status”. Click on the “Connectivity Interface Status”.

![Connectivity Interface Status anomalies](../assets/vxlan-single-site-ndfc/img-078.png)

The reason for the anomalies is due to the interfaces that are administratively enabled however there is nothing connected to those ports.

Navigate to Connectivity, select the interfaces with the undesired state and disable them

![Interfaces with undesired state selected](../assets/vxlan-single-site-ndfc/img-080.png)

![Disable Interfaces confirmation](../assets/vxlan-single-site-ndfc/img-081.png)

Save and Deploy the configuration to shutdown the interfaces.

After the intervention, the fabric is fully Healthy without an anomaly.

![Fabric health after interface shutdown](../assets/vxlan-single-site-ndfc/img-082.png)

!!! note
    This was just an example to show how NDFC plays a role for Day-2 operations and enabling network operations to quickly spot any issue and resolve with ease.

Now let’s move on to further fabric verifications (underlay, overlay etc.)

To verify the switches in a vPC domain, navigate to Inventory >> VPC pairs as shown below.

![Inventory VPC pairs](../assets/vxlan-single-site-ndfc/img-084.png)

Before proceeding with the configurations, it is a good idea to perform verifications based on the configuration that has been pushed by NDFC.

Verify OSPF routing adjacency (underlay).

```text
Site1-L1# show ip ospf neig
OSPF Process ID UNDERLAY VRF default
Total number of neighbors: 3
Neighbor ID     Pri State            Up Time    Address          Interface
10.2.0.5          1 FULL/ -          1w1d       10.4.0.17        Eth1/1
10.2.0.3          1 FULL/ -          1w1d       10.4.0.3         Eth1/2
10.2.0.2          1 FULL/ -          1w1d       10.4.0.1         Vlan3600
```

```text
Site1-L2# show ip ospf neig
OSPF Process ID UNDERLAY VRF default
Total number of neighbors: 3
Neighbor ID     Pri State            Up Time   Address     Interface
10.2.0.5          1 FULL/ -          1w1d      10.4.0.11   Eth1/1
10.2.0.3          1 FULL/ -          1w1d      10.4.0.15   Eth1/2
10.2.0.6          1 FULL/ -          1w1d      10.4.0.0    Vlan3600
```

Note: VLAN 3600 is the VPC-Peer-Link SVI.

Verify PIM neighborship.

```text
Site1-L1# show ip pim neig
PIM Neighbor Status for VRF "default"
Neighbor        Interface            Uptime       Expires     DR       Bidir- BFD      ECMP Redirect
                                                                      Priority Capable State       Capable
10.4.0.17       Ethernet1/1               1w6d    00:01:40    1        yes     n/a      no
10.4.0.3        Ethernet1/2               1w6d    00:01:20    1        yes     n/a      no
10.4.0.1        Vlan3600                  1w6d    00:01:31    1        yes     n/a      no
```

```text
Site1-L2# show ip pim neig
PIM Neighbor Status for VRF "default"
Neighbor        Interface            Uptime       Expires     DR       Bidir- BFD      ECMP Redirect
                                                                      Priority Capable State       Capable
10.4.0.11       Ethernet1/1               1w6d    00:01:41    1        yes     n/a      no
10.4.0.15       Ethernet1/2               1w6d    00:01:24    1        yes     n/a      no
10.4.0.0        Vlan3600                  1w6d    00:01:42    1        yes     n/a      no
Site1-L2#
```

Verify the BGP overlay (do this on all devices).

Site1-L1

```text
Site1-L1# show bgp l2vpn evpn summary
BGP summary information for VRF default, address family L2VPN EVPN
BGP router identifier 10.2.0.6, local AS number 65000
BGP table version is 158, L2VPN EVPN config peers 2, capable peers 2

Neighbor         V    AS        MsgRcvd      MsgSent   TblVer    InQ OutQ Up/Down State/PfxRcd
10.2.0.3         4 65000          20225        20141      158      0    0     1w6d 0
10.2.0.5         4 65000          20225        20141      158      0    0     1w6d 0
```

After all the configuration verifications are completed, the next step is to define the Network(s) and VRF(s), which will enable the user to achieve multi-tenant configuration.

## Network & VRF Configuration

This section will showcase how a tenant VRF, Layer-3 Virtual Network Identifier (VNI) and Network is configured. A tenant VRF separates routing domains between tenant overlays. The L3VNI is required for inter-VXLAN routing, and it is associated to a tenant VRF. Under Networks is where the L2VNIs along with their associated VLANs are created.

From the Fabric Overview, navigate to Segmentation and Security >> VRFs >> Actions and Create:

![Segmentation and Security VRFs create action](../assets/vxlan-single-site-ndfc/img-086.png)

![Create VRF form](../assets/vxlan-single-site-ndfc/img-087.png)

The Advanced options are left as defaults.

![Create VRF advanced options](../assets/vxlan-single-site-ndfc/img-088.png)

The configuration will show on the dashboard and the VRF’s settings can be edited if required.

![VRF dashboard](../assets/vxlan-single-site-ndfc/img-090.png)

Now let’s create the desired networks: PROD_1_NET & PROD_2_NET. Both these networks will be associated to the previously configured PROD_VRF.

From the Fabric Overview, navigate to Segmentation and Security >> Networks >> Actions and Create:

![Create Network action](../assets/vxlan-single-site-ndfc/img-091.png)

![Create Network PROD_1_NET](../assets/vxlan-single-site-ndfc/img-092.png)

![Create Network PROD_1_NET advanced parameters](../assets/vxlan-single-site-ndfc/img-093.png)

The second network is created below.

![Create Network PROD_2_NET](../assets/vxlan-single-site-ndfc/img-095.png)

![Create Network PROD_2_NET advanced parameters](../assets/vxlan-single-site-ndfc/img-096.png)

The Advanced Settings for both networks are left as default.

![Create Network advanced settings](../assets/vxlan-single-site-ndfc/img-097.png)

The configuration will show on the dashboard and each network’s settings can be edited if required

![Networks dashboard](../assets/vxlan-single-site-ndfc/img-098.png)

## Endpoint Attachment

In a VXLAN fabric, endpoints can can connect to the fabric in different attachment modes, depending on redundancy and load-balancing needs. The different modes of connectivity are highlighted in the Table below.

| Attachment Type | Description | VTEP Role | Redundancy | Load Balancing |
| --- | --- | --- | --- | --- |
| Single-Homed | Connected to one leaf | Unique VTEP | None | No |
| Multi-Homed (vPC) | Connected via vPC to two leafs | Shared Anycast VTEP | Active-Active | Yes |
| Active/Standby | Dual-attached, one link will be active at a time. | Individual VTEPs | Active-Standby | No |

In this lab single-homed server attachment configurations will be put in place. The interfaces required to attach servers will be configured as access ports.

To achieve this configuration, navigate to Connectivity > Interfaces >> Edit Configuration. Change the Interface policy from “int_trunk_host” to “int_access_host”. The rest of the configuration can be left as default or modified according to the user’s requirements

![Connectivity interfaces edit configuration](../assets/vxlan-single-site-ndfc/img-100.png)

![Edit interface Site1-L1 Ethernet1/5](../assets/vxlan-single-site-ndfc/img-101.png)

![Edit interface Site1-L2 Ethernet1/5](../assets/vxlan-single-site-ndfc/img-102.png)

Note: No VLAN is specified for the interface at this point.

After the interfaces’ desired configuration has been defined, Click Deploy. At this point you can review the configuration that will be pushed to each switch.

![Deploy interfaces configuration](../assets/vxlan-single-site-ndfc/img-104.png)

Review the “Pending config” and verify the changes that will be deployed. The Side-by-side comparison shows that the interface(s) will be changed from trunk to access.

![Pending interface side-by-side comparison](../assets/vxlan-single-site-ndfc/img-105.png)

After deploying the configuration, the next step is to attach these interfaces to the network.

Select the interface of choice >> Actions >> Edit Configuration >> Attachments

![Edit interface attachments](../assets/vxlan-single-site-ndfc/img-106.png)

Select the Network under which the selected interface belongs to.

![Select network attachment](../assets/vxlan-single-site-ndfc/img-108.png)

Click on Actions >> Interface Attach

![Interface Attach action](../assets/vxlan-single-site-ndfc/img-109.png)

After the interface has been attached, the configuration can be deployed.

Click on Actions >> Preview to see the configurations that will be deployed.

![Preview interface attachment](../assets/vxlan-single-site-ndfc/img-110.png)

Click on Actions >> Deploy for NDFC to push the configuration to the switches and monitor the progress until the deployment has been completed successfully.

![Interface attachment deployment complete](../assets/vxlan-single-site-ndfc/img-111.png)

Perform the same steps for the second interface on Leaf-2.

Select the interface.

![Select second interface](../assets/vxlan-single-site-ndfc/img-113.png)

Select the network to attach the interface to.

![Select second network attachment](../assets/vxlan-single-site-ndfc/img-114.png)

Deploy

![Deploy second interface attachment](../assets/vxlan-single-site-ndfc/img-115.png)

Deployment Completed.

![Second interface deployment completed](../assets/vxlan-single-site-ndfc/img-116.png)

Verify that the interfaces on the leaf switches have been configured correctly, each with the correct interface mode and access VLAN ID.

```text
Site1-L1# show run int eth1/5

!Command: show running-config interface Ethernet1/5

interface Ethernet1/5
  description Server-1
  switchport access vlan 2300
  spanning-tree port type edge
  spanning-tree bpduguard enable
  mtu 9216
```

```text
Site1-L2# show run int eth1/5

!Command: show running-config interface Ethernet1/5

interface Ethernet1/5
  description Server-2
  switchport access vlan 2301
  spanning-tree port type edge
  spanning-tree bpduguard enable
  mtu 9216
```

Due to attaching an interface to a Network (which was already configured with a VLAN ID), the interface will be assigned to this respective VLAN ID.

Verify the nve interface status.

```text
Site1-L1# show interface nve 1
nve1 is up
admin state is up, Hardware: NVE
  MTU 9216 bytes
  Encapsulation VXLAN
  Auto-mdix is turned off
  RX
     ucast: 0 pkts, 0 bytes - mcast: 0 pkts, 0 bytes
  TX
     ucast: 0 pkts, 0 bytes - mcast: 0 pkts, 0 bytes
```

```text
Site1-L2# show interface nve 1
nve1 is up
admin state is up, Hardware: NVE
  MTU 9216 bytes
  Encapsulation VXLAN
  Auto-mdix is turned off
  RX
     ucast: 0 pkts, 0 bytes - mcast: 0 pkts, 0 bytes
  TX
     ucast: 0 pkts, 0 bytes - mcast: 0 pkts, 0 bytes
```

Verify the VLAN to vn-segment mapping

```text
Site1-L1# show nve vni
Codes: CP - Control Plane        DP - Data Plane
       UC - Unconfigured         SA - Suppress ARP
       S-ND - Suppress ND
       SU - Suppress Unknown Unicast
       Xconn - Crossconnect
       MS-IR - Multisite Ingress Replication
       HYB - Hybrid IRB mode

Interface VNI      Multicast-group   State Mode Type [BD/VRF]
Flags
--------- -------- ----------------- ----- ---- ----------------
nve1      30000    239.1.1.0         Up    CP   L2 [2300]
nve1      30001    239.1.1.0         Up    CP   L2 [2301]
nve1      50000    n/a               Up    CP   L3 [prod_vrf]
```

```text
Site1-L2# show nve vni
Codes: CP - Control Plane        DP - Data Plane
       UC - Unconfigured         SA - Suppress ARP
       S-ND - Suppress ND
       SU - Suppress Unknown Unicast
       Xconn - Crossconnect
       MS-IR - Multisite Ingress Replication
       HYB - Hybrid IRB mode

Interface VNI      Multicast-group   State Mode Type [BD/VRF]
Flags
--------- -------- ----------------- ----- ---- ---------------
nve1      30000    239.1.1.0         Up    CP   L2 [2300]
nve1      30001    239.1.1.0         Up    CP   L2 [2301]
nve1      50000    n/a               Up    CP   L3 [prod_vrf]
```

Connectivity Verification

Verify that each server can ping its respective default gateway.

Server-1

![Server-1 ping default gateway](../assets/vxlan-single-site-ndfc/img-119.png)

Server-2

![Server-2 ping default gateway](../assets/vxlan-single-site-ndfc/img-120.png)

Verify that the servers can communicate with each other.

Server-1

![Server-1 ping Server-2](../assets/vxlan-single-site-ndfc/img-121.png)

Server-2

![Server-2 ping Server-1](../assets/vxlan-single-site-ndfc/img-122.png)

For more labs visit my GitHub repo: [https://github.com/TitusM/Cisco-Data-Center](https://github.com/TitusM/Cisco-Data-Center)

## References

- [https://www.ciscolive.com/on-demand/on-demand-library.html?search=NDFC&search=NDFC#/video/1751295632034001Sxim](https://www.ciscolive.com/on-demand/on-demand-library.html?search=NDFC&search=NDFC#/video/1751295632034001Sxim)
- [https://www.cisco.com/c/en/us/td/docs/dcn/whitepapers/cisco-vxlan-bgp-evpn-design-and-implementation-guide.html](https://www.cisco.com/c/en/us/td/docs/dcn/whitepapers/cisco-vxlan-bgp-evpn-design-and-implementation-guide.html)
- [https://www.cisco.com/c/en/us/td/docs/dcn/nx-os/nexus9000/105x/configuration/vxlan/cisco-nexus-9000-series-nx-os-vxlan-configuration-guide-release-105x/m_overview.html](https://www.cisco.com/c/en/us/td/docs/dcn/nx-os/nexus9000/105x/configuration/vxlan/cisco-nexus-9000-series-nx-os-vxlan-configuration-guide-release-105x/m_overview.html)
- [https://www.ciscolive.com/on-demand/on-demand-library.html?search=VXLAN#/video/1751036939701001hVz0](https://www.ciscolive.com/on-demand/on-demand-library.html?search=VXLAN#/video/1751036939701001hVz0)
- [https://www.ciscolive.com/on-demand/on-demand-library.html?search=VXLAN#/video/1751036941693001hMFt](https://www.ciscolive.com/on-demand/on-demand-library.html?search=VXLAN#/video/1751036941693001hMFt)
