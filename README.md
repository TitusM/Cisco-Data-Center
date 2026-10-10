# 🚀 Cisco Data Center Labs

![Labs](https://img.shields.io/badge/Data%20Center-Labs-blue)
![Cisco](https://img.shields.io/badge/Cisco-ACI%2C%20VXLAN%2C%20Nexus-informational)
![Terraform](https://img.shields.io/badge/IaC-Terraform-623CE4?logo=terraform)
![Author](https://img.shields.io/badge/Author-TitusM-blueviolet)

> ## 📖 Read the labs online
>
> The labs are published as a searchable, easy-to-read website. **For the best experience, visit:**
>
> ### 👉 [titusm.github.io/Cisco-Data-Center](https://titusm.github.io/Cisco-Data-Center/)
>
> This repository holds the source files, configurations, and automation code behind that site.

[![Open the Lab Site](https://img.shields.io/badge/Open-Lab%20Website-4051B5?style=for-the-badge&logo=materialformkdocs&logoColor=white)](https://titusm.github.io/Cisco-Data-Center/)

Hands-on technical labs for **CCIE Data Center** candidates, Data Center enthusiasts, and practicing engineers. Build real Data Center technologies from the ground up, verify how they operate, deliberately break them, and troubleshoot the failures.

**Build it. Verify it. Break it. Troubleshoot it.**

## 🧩 Lab Topics

Each topic below is published as a guided lab on the [lab website](https://titusm.github.io/Cisco-Data-Center/).

- **🖥️ [UCS & SAN](https://titusm.github.io/Cisco-Data-Center/ucs-san/)**
  - Standalone labs for service profiles and identity pools.

- **🔗 [NX-OS](https://titusm.github.io/Cisco-Data-Center/nx-os/)**
  - Layer 2 switching and virtual Port-Channel (vPC) configuration and troubleshooting.

- **🏢 [ACI (Application Centric Infrastructure)](https://titusm.github.io/Cisco-Data-Center/aci/)**
  - Fabric bring-up, vPC, contracts, ESGs, L4-L7 Policy-Based Redirect, L3Out (BGP & OSPF), transit routing, shared L3Out, inter-VRF route leaking, Multi-Pod, Multi-Site, and SPAN.

- **🌐 [VXLAN EVPN](https://titusm.github.io/Cisco-Data-Center/vxlan-evpn/)**
  - VXLAN BGP EVPN single-site and multi-site via CLI, plus fabric build-out with Cisco NDFC.

- **🤖 Automation**
  - Infrastructure as Code and automation for ACI _(Terraform / Nexus-as-Code)_, VXLAN _(Ansible / Nexus-as-Code)_, and NX-OS _(Ansible)_.

- **🛡️ Network Security**
  - Data Center AAA and security-related labs.

## 🛠 Technologies Used

- 🖥️ Cisco Data Center platforms _(NX-OS, ACI, Nexus Dashboard)_
- 🛠️ Terraform _(Infrastructure as Code for ACI automation)_
- 🛠️ Ansible _(Infrastructure as Code for VXLAN automation)_

## 🏁 Getting Started

### ✅ Prerequisites

- 🟦 Access to a Cisco ACI fabric _(with APIC)_
- 🟧 Access to Cisco Modeling Labs [(CML)](https://developer.cisco.com/modeling-labs/)

### ▶️ Usage (for ACI automation labs)

1. Clone the repo:
   ```sh
   git clone https://github.com/TitusM/Cisco-Data-Center.git
   cd Cisco-Data-Center
   ```
2. Navigate to the relevant lab directory (e.g., `ACI/Nexus-As-Code - ACI/Initial Fabric Deployment`)
3. Run Terraform:
   ```sh
   terraform init
   terraform plan
   terraform apply
   ```
4. ✏️ Replace placeholders in YAML files with values specific to your deployment.

## 👤 Author

- [TitusM](https://github.com/TitusM)

## ℹ️ Additional Information

- 🌍 Browse all labs on the website: **[titusm.github.io/Cisco-Data-Center](https://titusm.github.io/Cisco-Data-Center/)**
- 🗂 To work with the raw files and configurations, explore the subfolders in this repository.

---

🔗 **[Open the lab website →](https://titusm.github.io/Cisco-Data-Center/)**
