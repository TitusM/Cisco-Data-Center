terraform {
  required_providers {
    aci = {
        source = "CiscoDevNet/aci"
    }
  }
}

provider "aci" {
  username = "username"
  password = "password"
  url      = "https://APIC-IP"
  annotation = "false"
}

module "aci" {
    source = "netascode/nac-aci/aci"
    version = "0.9.3"

    yaml_directories = ["data"]

    manage_access_policies    = false
    manage_fabric_policies    = true
    manage_pod_policies       = true
    manage_node_policies      = true
    manage_interface_policies = false
    manage_tenants            = false
}