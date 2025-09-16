
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
      domain  = local.cluster_name
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
    dedicated = 8192
    floating  = 4096
  }

  network_device {
    queues = 4
  }

  operating_system {
    type = "l26"
  }

  lifecycle {
    ignore_changes = [agent, disk[0].file_id, usb]
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
    size         = 32
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

  hostpci {
    device = "hostpci0"
    id     = "0000:00:02.0"
    pcie   = false
    rombar = true
    xvga   = false
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
    floating  = 4096
  }

  network_device {
    queues = 4
  }

  operating_system {
    type = "l26"
  }

  lifecycle {
    ignore_changes = [agent, disk[0].file_id, usb]
  }
}

resource "talos_machine_configuration_apply" "proxmox_control_plane" {
  for_each = proxmox_virtual_environment_vm.talos_controlplane

  endpoint                    = split("/", each.value.initialization[0].ip_config[0].ipv4[0].address)[0]
  node                        = each.value.name
  machine_configuration_input = data.talos_machine_configuration.control_plane.machine_configuration
  client_configuration        = talos_machine_secrets.secrets.client_configuration
  config_patches = [
    yamlencode({ machine = {
      network = {
        hostname = "${each.value.name}.${local.domain}"
      }
    } }),
    yamlencode(module.deepmerge-controlplane-proxmox.merged),
  ]

  lifecycle {
    ignore_changes = [config_patches]
  }
}

resource "talos_machine_configuration_apply" "proxmox_worker" {
  for_each = proxmox_virtual_environment_vm.talos_worker

  endpoint                    = split("/", each.value.initialization[0].ip_config[0].ipv4[0].address)[0]
  node                        = each.value.name
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  client_configuration        = talos_machine_secrets.secrets.client_configuration
  config_patches = [
    yamlencode({ machine = {
      network = {
        hostname = "${each.value.name}.${local.domain}"
      }
    } }),
    yamlencode(module.deepmerge-worker-proxmox.merged),
    templatefile("${path.module}/extensionserviceconfig/cloudflare-config.yaml", {}),
    # templatefile("${path.module}/extensionserviceconfig/tailscale.yaml", {})
    templatefile("${path.module}/volumeconfig/ephemeral.tftpl", {
      match = "disk.dev_path == '/dev/sdb'"
    }),
    templatefile("${path.module}/uservolumeconfig/local-path-provisioner.tftpl", {
      match = "disk.dev_path == '/dev/sdb'"
    }),
    templatefile("${path.module}/uservolumeconfig/longhorn.tftpl", {
      match = "disk.dev_path == '/dev/sdb'"
    }),
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
    yamlencode({ machine = {
      network = {
        hostname = "${each.value.name}.${local.domain}"
      }
    } }),
    yamlencode(module.deepmerge-worker-turingpi.merged),
    templatefile("${path.module}/extensionserviceconfig/cloudflare-config.yaml", {}),
    # templatefile("${path.module}/extensionserviceconfig/tailscale.yaml", {})
    templatefile("${path.module}/volumeconfig/ephemeral.tftpl", {
      match = "disk.transport == 'nvme'"
    }),
    templatefile("${path.module}/uservolumeconfig/local-path-provisioner.tftpl", {
      match = "disk.transport == 'nvme'"
    }),
    templatefile("${path.module}/uservolumeconfig/longhorn.tftpl", {
      match = "disk.transport == 'nvme'"
    }),
  ]
}

resource "talos_machine_bootstrap" "bootstrap" {
  depends_on           = [talos_machine_configuration_apply.proxmox_control_plane[0]]
  node                 = tolist(local.proxmox_controlplanes)[0].address
  endpoint             = tolist(local.proxmox_controlplanes)[0].address
  client_configuration = talos_machine_secrets.secrets.client_configuration
}

# resource "talos_cluster_kubeconfig" "kubeconfig" {
#   depends_on           = [talos_machine_bootstrap.bootstrap]
#   client_configuration = talos_machine_secrets.secrets.client_configuration
#   node                 = tolist(local.controlplanes)[0].address
# }

resource "talos_cluster_kubeconfig" "kubeconfig" {
  depends_on           = [talos_machine_bootstrap.bootstrap]
  client_configuration = talos_machine_secrets.secrets.client_configuration
  node                 = tolist(local.controlplanes)[0].address
}

resource "flux_bootstrap_git" "bootstrap" {
  depends_on = [github_repository_deploy_key.flux, resource.talos_cluster_kubeconfig.kubeconfig]
  path       = "clusters/${local.cluster_name}"
}
