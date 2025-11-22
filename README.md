# Cisco-Data Center
# 🚀 Cisco Data Center

![Labs](https://img.shields.io/badge/Data%20Center-Labs-blue)
![Cisco](https://img.shields.io/badge/Cisco-ACI%2C%20VXLAN%2C%20Nexus-informational)
![Terraform](https://img.shields.io/badge/IaC-Terraform-623CE4?logo=terraform)
![Author](https://img.shields.io/badge/Author-TitusM-blueviolet)

This repository contains lab configurations for Cisco Data Center technologies, primarily focused on **CCNP/CCIE-level** labs. Its purpose is to provide practical resources for learning and deploying Cisco Data Center solutions in a lab environment.

## 🧩 Sections & Features

- **🏢 ACI (Application Centric Infrastructure)**
  - Configurations, troubleshooting, and automation _(Infrastructure as Code using Terraform)_.
  - Labs include initial fabric deployment, vPC configuration, and Nexus as Code integration.

- **🌐 VXLAN**
  - Labs covering VXLAN deployment and configuration.

- **🔗 Data Center Layer 2 Networking**
  - Labs and configs focusing on L2 switching and protocols.

- **🛡️ Network Security**
  - Data Center AAA and security-related labs.

## 🛠 Technologies Used

- 🖥️ Cisco Data Center platforms _(NX-OS, ACI, Nexus Dashboard)_
- 🛠️ Terraform _(Infrastructure as Code for ACI automation)_

## 🏁 Getting Started

### ✅ Prerequisites

- 🟦 Access to a Cisco ACI fabric _(with APIC)_
- 🟧 Access to Cisco Modeling Labs [(CML)](https://developer.cisco.com/modeling-labs/)
- 🟪 Terraform installed ([Install Guide](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli))
- 🟨 Valid Terraform provider for Cisco ACI

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

- 🗂 For a full list of available labs and configurations, explore the subfolders in the repository.
- 📄 Each section includes domain-specific README files for further guidance.

---

🔗 For more details, see the [repository on GitHub](https://github.com/TitusM/Cisco-Data-Center).
