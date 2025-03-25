This repository provides an automated approach to bring up a Cisco ACI fabric using Infrastructure as Code (IaC) principles with Nexus as Code.

Overview
The Terraform scripts in this repository will:
1.	Register ACI devices into the fabric.
2.	Configure the Pod Policy, including Date & Time settings (NTP servers).
3.	Create a Pod Policy Group and associate it with the defined Date & Time Policy.
4.	Define a Pod Profile and link it to the Pod Policy Group.
5.	Assign Out-of-Band (OOB) Management IP addresses to ACI devices.
6.	Configure a DNS Profile and associate it with the default Out-of-Band Management EPG.
7.	Set the ACI Pod BGP Autonomous System Number (ASN).
8.	Designate the Spine nodes as BGP Route Reflectors.
   
Prerequisites

Ensure you have the following before proceeding:

1. Access to an ACI fabric with APIC connectivity
2. Terraform installed on your system (https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
3. A valid Terraform provider for ACI configured in the environment

Usage

To bring up the ACI fabric, execute the following Terraform commands:
1. terraform init
2. terraform plan
3. terraform apply

These steps will initialize the Terraform workspace, generate an execution plan, and apply the configuration to your ACI fabric.

