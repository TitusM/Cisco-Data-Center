# Cisco Data Center Labs

Hands-on technical labs for CCIE Data Center candidates, Data Center enthusiasts, and practicing engineers.

Build real Data Center technologies from the ground up, verify how they operate, deliberately break them, troubleshoot the failures, and understand how the pieces work together.

**Build it. Verify it. Break it. Troubleshoot it.**

<div class="grid" markdown>

[Explore the Labs](#technology-domains){ .md-button .md-button--primary }
[Start CCIE DC Practice](ucs-san/00-overview.md){ .md-button }
[Choose Your Path](#who-are-these-labs-for){ .md-button }

</div>

## Who Are These Labs For?

<div class="grid cards" markdown>

-   :material-certificate-outline: **CCIE Data Center Candidates**

    ---

    Build configuration speed, verification habits, and troubleshooting discipline against technologies found in the CCIE Data Center blueprint — from-scratch configuration, operational verification, and independent practice toward capstone-style scenarios.

    [Prepare for CCIE DC](#preparing-for-ccie-data-center)

-   :material-flask-outline: **Data Center Enthusiasts**

    ---

    Go beyond theory by building UCS, SAN, NX-OS, ACI, and VXLAN EVPN technologies in realistic lab topologies. Progress from individual capabilities to complete systems without turning the site into a theory course.

    [Explore Technologies](#technology-domains)

-   :material-server-network: **Data Center Professionals**

    ---

    Reproduce real implementation and troubleshooting scenarios, validate expected behavior, and use the labs as a practical technical reference grounded in official documentation and design assumptions.

    [Practice Real-World Scenarios](#technology-domains)

</div>

## How These Labs Work

<div class="grid cards" markdown>

-   **Build**

    Configure the technology from a defined starting state.

-   **Verify**

    Prove that the control plane, data plane, and expected services operate correctly.

-   **Break**

    Introduce realistic faults or remove dependencies where appropriate.

-   **Troubleshoot**

    Use operational evidence to identify the actual root cause.

-   **Restore**

    Return the environment to the intended working state and prove recovery.

</div>

Configuration is not the finish line. A lab is complete when the intended service works and you can prove why it works.

## Technology Domains

<div class="grid cards" markdown>

-   :material-server: **[UCS & SAN](ucs-san/00-overview.md)**

    ---

    Compute identity, service profiles, Fabric Interconnects, Fibre Channel, FCoE, zoning, NPV/NPIV, SAN connectivity, and boot-from-SAN workflows.

-   :material-lan: **[NX-OS](nx-os/index.md)**

    ---

    Core Nexus switching technologies including Layer 2, Layer 3, vPC, resiliency, and operational troubleshooting.

-   :material-hexagon-multiple-outline: **[ACI](aci/index.md)**

    ---

    Fabric deployment, policy, segmentation, external connectivity, routing, Multi-Pod, Multi-Site, visibility, and troubleshooting.

-   :material-router-network: **[VXLAN EVPN](vxlan-evpn/index.md)**

    ---

    Build and understand VXLAN EVPN fabrics from the underlay through the overlay, endpoint learning, routing, and failure scenarios.

    :material-progress-wrench: *Labs in development*

</div>

## Lab Types

The platform is built around four lab types, introduced progressively as content is published.

`Guided Labs`
: Connected, end-to-end exercises that build a technology or solution progressively.

`Standalone Labs`
: Focused exercises for drilling a particular technology, feature, or configuration task.

`Troubleshooting Labs`
: Environments that begin with a failure or are deliberately broken and require root-cause analysis.

`Capstone Labs`
: Outcome-driven scenarios with reduced guidance that combine multiple skills and technologies.

## Built for the Lab. Valid in the Real World.

The content is designed around the same questions engineers should ask in production environments:

- What is the intended state?
- What dependencies must exist?
- How do I prove the configuration is operational?
- What should normal behavior look like?
- What breaks when a dependency fails?
- What evidence identifies the root cause?
- How do I restore and validate service?

The goal is not to memorize configuration snippets. It is to understand the system well enough to deploy it, verify it, and troubleshoot it.

## Engineering Principles

<div class="grid cards" markdown>

-   **Outcome Driven**

    Labs work toward an operational result rather than stopping when commands have been entered.

-   **Verification First**

    Configuration tasks are paired with operational verification.

-   **Troubleshooting Focused**

    Where appropriate, scenarios include deliberate failures and recovery.

-   **Real Topologies**

    Technologies are presented in the context of actual Data Center architectures rather than isolated CLI examples.

-   **Official Documentation**

    Technical concepts are grounded in official Cisco configuration and design documentation wherever possible.

-   **Production Mindset**

    Labs teach dependencies, redundancy, failure domains, and operational impact — not just syntax.

</div>

## Preparing for CCIE Data Center?

Use the labs to reinforce blueprint topics through configuration, verification, and troubleshooting rather than passive theory review.

The platform is progressively expanding to provide:

- blueprint-aligned labs
- guided configuration
- standalone drills
- troubleshooting scenarios
- reduced-guidance exercises
- cross-technology scenarios

These labs are intended to complement official Cisco training, documentation, and hands-on practice — not to replace them, and not to reproduce the CCIE lab exam itself.

## Start Practicing

<div class="grid" markdown>

[UCS & SAN](ucs-san/00-overview.md){ .md-button }
[NX-OS](nx-os/index.md){ .md-button }
[ACI](aci/index.md){ .md-button }
[VXLAN EVPN](vxlan-evpn/index.md){ .md-button }

</div>

---

*This is an independent educational lab resource. Cisco, Cisco Systems, CCIE and related product names are trademarks of Cisco Systems, Inc. This content is not an official Cisco training product and should be used alongside current Cisco documentation.*
