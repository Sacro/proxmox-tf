
resource "proxmox_virtual_environment_download_file" "talos_img" {
  for_each = setunion(local.proxmox_controlplanes[*].node, local.proxmox_workers[*].node)

  node_name = each.value

  content_type            = "iso"
  datastore_id            = "local"
  file_name               = "${local.talos_amd64_filename}-${local.talos_version}.img"
  url                     = local.talos_amd64_url
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

  # Holds the installer
  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.talos_img[each.value.node].id
    interface    = "scsi0"
    discard      = "on"
    size         = 10
  }

  # Holds the OS
  disk {
    datastore_id = "local-lvm"
    discard      = "on"
    file_format  = "raw"
    interface    = "scsi1"
    size         = 20
    ssd          = true
  }

  initialization {
    dns {
      domain  = local.domain
      servers = local.nameservers
    }

    ip_config {
      ipv4 {
        address = "${each.value.address}/${local.subnet}"
        gateway = local.gateway
      }
    }
  }

  memory {
    dedicated = 4096
  }

  network_device {}

  operating_system {
    type = "l26"
  }

  lifecycle {
    ignore_changes = [agent, disk[0].file_id]
  }
}

resource "proxmox_virtual_environment_vm" "talos_worker" {
  for_each = {
    for index, item in local.proxmox_workers :
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
    units = 100 // default, but should mean control plane isn't locked out
  }

  # Holds the installer
  disk {
    datastore_id = "local-lvm"
    file_id      = proxmox_virtual_environment_download_file.talos_img[each.value.node].id
    interface    = "scsi0"
    discard      = "on"
    size         = 10
  }

  # Holds the OS
  disk {
    datastore_id = "local-lvm"
    discard      = "on"
    file_format  = "raw"
    interface    = "scsi1"
    size         = 20
    ssd          = true
  }

  # Storage partition
  disk {
    datastore_id = "local-lvm"
    discard      = "on"
    file_format  = "raw"
    interface    = "scsi2"
    size         = 250
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
    ignore_changes = [agent, disk[0].file_id]
  }
}

resource "talos_machine_configuration_apply" "proxmox_control_plane" {
  for_each = {
    for index, item in local.proxmox_controlplanes :
    item.name => item
  }

  depends_on = [proxmox_virtual_environment_vm.talos_controlplane]

  endpoint                    = each.value.address
  node                        = each.value.name
  machine_configuration_input = data.talos_machine_configuration.control_plane.machine_configuration
  client_configuration        = talos_machine_secrets.secrets.client_configuration
  config_patches = [
    yamlencode(module.deepmerge-controlplane-proxmox.merged)
  ]
}

resource "talos_machine_configuration_apply" "proxmox_worker" {
  for_each = {
    for index, item in local.proxmox_workers :
    item.name => item
  }

  depends_on = [proxmox_virtual_environment_vm.talos_worker]

  endpoint                    = each.value.address
  node                        = each.value.name
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  client_configuration        = talos_machine_secrets.secrets.client_configuration
  config_patches = [
    yamlencode(module.deepmerge-worker-proxmox.merged),
  ]
}

resource "talos_machine_configuration_apply" "turingpi_worker" {
  for_each = {
    for index, item in local.turingpi_workers :
    item.name => item
  }

  endpoint                    = each.value.dhcp_address
  node                        = each.value.dhcp_address
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  client_configuration        = talos_machine_secrets.secrets.client_configuration
  config_patches = [
    yamlencode(module.deepmerge-worker-turingpi.merged),
  ]
}


resource "talos_machine_bootstrap" "bootstrap" {
  depends_on           = [talos_machine_configuration_apply.proxmox_control_plane[0]]
  node                 = tolist(local.proxmox_controlplanes)[0].address
  endpoint             = tolist(local.proxmox_controlplanes)[0].address
  client_configuration = talos_machine_secrets.secrets.client_configuration
}

data "talos_cluster_kubeconfig" "kubeconfig" {
  depends_on           = [talos_machine_bootstrap.bootstrap]
  client_configuration = talos_machine_secrets.secrets.client_configuration
  node                 = tolist(local.controlplanes)[0].address
}

resource "flux_bootstrap_git" "bootstrap" {
  depends_on = [github_repository_deploy_key.flux, data.talos_cluster_kubeconfig.kubeconfig]
  path       = "clusters/${local.cluster_name}"
}
