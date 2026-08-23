# ACI

Hands-on Cisco ACI labs covering fabric deployment, policy and segmentation, external routing, multi-fabric architectures, and operations.

Work through individual capabilities or combine them to understand how the ACI fabric behaves as a complete Data Center system.

**New to the ACI labs?** Suggested progression:

Fabric Foundation → Policy & Segmentation → External Connectivity → Routing & Route Sharing → Multi-Fabric → Operations & Visibility

This is a suggestion, not a requirement — jump straight to whichever lab you need.

<div class="grid cards" markdown>

-   :material-hexagon-outline: **Fabric Foundation**

    ---

    Build the ACI fabric foundation, onboard nodes, establish access connectivity, and verify the fabric is operational before tenant services are introduced.

    - **[Fabric Bring Up – from Scratch!](fabric-bring-up.md)** · Guided Lab
    - **[Virtual Port-Channel (vPC)](virtual-port-channel-vpc.md)** · Standalone Lab

-   :material-shield-check-outline: **Policy & Segmentation**

    ---

    Practice ACI policy, segmentation, endpoint grouping, and communication control using the application policy model.

    - **[Contracts](contracts.md)** · Standalone Lab
    - **[Endpoint Security Groups (ESGs)](endpoint-security-groups.md)** · Standalone Lab
    - **[L4-L7 Policy-Based Redirect (PBR)](l4-l7-pbr.md)** · Standalone Lab

-   :material-router-network-wireless: **External Connectivity**

    ---

    Connect ACI tenants to external routed networks and validate adjacency, route exchange, endpoint reachability, and policy enforcement.

    - **[L3OUT (BGP & OSPF) Configuration](l3out-bgp-ospf.md)** · Standalone Lab

-   :material-routes: **Routing & Route Sharing**

    ---

    Explore how ACI handles transit traffic, shared external connectivity, route leaking, and controlled routing between tenant contexts.

    - **[Transit Routing Configuration](transit-routing.md)** · Standalone Lab
    - **[Shared L3OUT (VRF Leaking)](shared-l3out.md)** · Standalone Lab
    - **[Inter-VRF Route-Leaking](inter-vrf-route-leaking.md)** · Standalone Lab

-   :material-server-network: **Multi-Fabric**

    ---

    Build and operate ACI across multiple pods or sites and understand the control-plane, data-plane, and orchestration dependencies involved.

    - **[Multi-Pod Fabric Bring Up – from Scratch!](multipod-fabric-bring-up.md)** · Guided Lab
    - **[Multi-Site Configuration](multi-site-bring-up.md)** · Guided Lab

-   :material-magnify-scan: **Operations & Visibility**

    ---

    Observe ACI operational state, inspect traffic, validate endpoint behavior, and gather evidence before troubleshooting.

    - **[Local SPAN, Ethanalyzer & SPAN-to-CPU](local-span.md)** · Standalone Lab

</div>

## Coming soon

- Initial fabric deployment via Nexus-as-Code
- Remote Leaf topologies
