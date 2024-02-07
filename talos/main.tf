locals {
  nodes         = ["proxmox01", "proxmox02", "proxmox03"]
  talos_version = "v1.6.4"
}

resource "proxmox_virtual_environment_download_file" "talos_iso" {
  for_each  = toset(local.nodes)
  node_name = each.key

  content_type = "iso"
  datastore_id = "local"
  file_name    = "metal-amd64.iso"
  url          = "https://github.com/siderolabs/talos/releases/download/${local.talos_version}/metal-amd64.iso"
}


# https://www.talos.dev/v1.6/introduction/system-requirements/
resource "proxmox_virtual_environment_vm" "talos_controlplane" {
  for_each  = toset(local.nodes)
  node_name = each.value

  name = "talos-controlplane"
  tags = ["talos", "terraform"]

  agent {
    enabled = false
  }

  cpu {
    cores = 4
    type  = "x86-64-v2-AES"
    units = 200
  }

  cdrom {
    enabled = true
    file_id = proxmox_virtual_environment_download_file.talos_iso[each.value].id
  }

  disk {
    datastore_id = "local-lvm"
    discard      = "on"
    file_format  = "raw"
    interface    = "scsi0"
    size         = 100
    ssd          = true
  }

  memory {
    dedicated = 2048
    floating  = 4096 - 2048
  }

  network_device {}

  operating_system {
    type = "l26"
  }
}

resource "proxmox_virtual_environment_vm" "talos_worker" {
  for_each  = toset(local.nodes)
  node_name = each.value

  name = "talos-worker"
  tags = ["talos", "terraform"]

  agent {
    enabled = false
  }

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
    units = 100 // default, but should mean control plane isn't locked out
  }

  cdrom {
    enabled = true
    file_id = proxmox_virtual_environment_download_file.talos_iso[each.value].id
  }

  disk {
    datastore_id = "local-lvm"
    discard      = "on"
    file_format  = "raw"
    interface    = "scsi0"
    size         = 100
    ssd          = true
  }

  memory {
    dedicated = 1024
    floating  = 8192 - 1024
  }

  network_device {}

  operating_system {
    type = "l26"
  }
}
