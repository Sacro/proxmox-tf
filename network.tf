locals {
  gateway = "192.168.15.254"
  nodes = toset([{
    name    = "proxmox01"
    address = "192.168.15.101/24"
    }, {
    name    = "proxmox02"
    address = "192.168.15.102/24"
    }, {
    name    = "proxmox03"
    address = "192.168.15.103/24"
  }])
  ports = ["enp1s0"]
}

resource "proxmox_virtual_environment_network_linux_bridge" "vmbr0" {
  for_each = {
    for index, node in local.nodes :
    node.name => node
  }

  node_name = each.value.name

  name       = "vmbr0"
  address    = each.value.address
  comment    = "managed by terraform"
  gateway    = local.gateway
  ports      = local.ports
  vlan_aware = false
}
