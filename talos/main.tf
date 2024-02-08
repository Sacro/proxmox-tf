
resource "proxmox_virtual_environment_download_file" "talos_img" {
  for_each = setunion(local.controlplanes[*].node, local.workers[*].node)

  node_name = each.value

  content_type            = "iso"
  datastore_id            = "local"
  file_name               = "${local.talos_filename}-${local.talos_version}.img"
  url                     = local.talos_url
  decompression_algorithm = "zst"
  overwrite               = false
}

# https://www.talos.dev/v1.6/introduction/system-requirements/
resource "proxmox_virtual_environment_vm" "talos_controlplane" {
  for_each = {
    for index, item in local.controlplanes :
    item.name => item
  }

  node_name = each.value.node

  name = each.value.name
  tags = ["talos", "terraform"]

  agent {
    enabled = false
  }

  cpu {
    cores = 4
    type  = "x86-64-v2-AES"
    units = 200
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.talos_img[each.value.node].id
    interface    = "scsi0"
    discard      = "on"
    size         = 10
  }

  disk {
    datastore_id = "local-lvm"
    discard      = "on"
    file_format  = "raw"
    interface    = "scsi1"
    size         = 100
    ssd          = true
  }

  disk {
    datastore_id = "local-lvm"
    discard      = "on"
    file_format  = "raw"
    interface    = "scsi2"
    size         = 100
    ssd          = true
  }

  initialization {
    dns {
      domain  = local.domain
      servers = [local.gateway]
    }

    ip_config {
      ipv4 {
        address = "${each.value.address}/${local.subnet}"
        gateway = local.gateway
      }
    }
  }

  memory {
    dedicated = 2048
  }

  network_device {}

  operating_system {
    type = "l26"
  }

  lifecycle {
    ignore_changes = [agent]
  }
}

resource "proxmox_virtual_environment_vm" "talos_worker" {
  for_each = {
    for index, item in local.workers :
    item.name => item
  }

  node_name = each.value.node

  name = each.value.name
  tags = ["talos", "terraform"]

  agent {
    enabled = false
  }

  cpu {
    cores = 2
    type  = "x86-64-v2-AES"
    units = 100 // default, but should mean control plane isn't locked out
  }

  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.talos_img[each.value.node].id
    interface    = "scsi0"
    discard      = "on"
    size         = 10
  }

  disk {
    datastore_id = "local-lvm"
    discard      = "on"
    file_format  = "raw"
    interface    = "scsi1"
    size         = 100
    ssd          = true
  }

  disk {
    datastore_id = "local-lvm"
    discard      = "on"
    file_format  = "raw"
    interface    = "scsi2"
    size         = 100
    ssd          = true
  }

  initialization {
    ip_config {
      ipv4 {
        address = "${each.value.address}/${local.subnet}"
        gateway = local.gateway
      }
    }
  }

  memory {
    dedicated = 8192
  }

  network_device {}

  operating_system {
    type = "l26"
  }

  lifecycle {
    ignore_changes = [agent]
  }
}

resource "talos_machine_configuration_apply" "control_plane" {
  for_each = {
    for index, item in local.controlplanes :
    item.name => item
  }

  depends_on = [proxmox_virtual_environment_vm.talos_controlplane]

  endpoint                    = each.value.address
  node                        = each.value.name
  machine_configuration_input = data.talos_machine_configuration.control_plane.machine_configuration
  client_configuration        = talos_machine_secrets.secrets.client_configuration
  config_patches = [
    yamlencode(module.deepmerge-controlplane.merged)
  ]
}

resource "talos_machine_configuration_apply" "worker" {
  for_each = {
    for index, item in local.workers :
    item.name => item
  }

  depends_on = [proxmox_virtual_environment_vm.talos_worker]

  endpoint                    = each.value.address
  node                        = each.value.name
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  client_configuration        = talos_machine_secrets.secrets.client_configuration
  config_patches = [
    yamlencode(module.deepmerge-worker.merged),
  ]
}

resource "talos_machine_bootstrap" "bootstrap" {
  depends_on           = [talos_machine_configuration_apply.control_plane[0]]
  node                 = tolist(local.controlplanes)[0].address
  endpoint             = tolist(local.controlplanes)[0].address
  client_configuration = talos_machine_secrets.secrets.client_configuration
}