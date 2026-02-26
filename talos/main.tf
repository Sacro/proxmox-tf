
resource "talos_machine_configuration_apply" "beelink_combined" {
  for_each = {
    for index, item in local.beelink_combined :
    item.name => item
  }

  endpoint                    = each.value.address
  node                        = each.value.name
  machine_configuration_input = data.talos_machine_configuration.combined.machine_configuration
  client_configuration        = talos_machine_secrets.secrets.client_configuration
  config_patches = [
    yamlencode(provider::deepmerge::mergo(
      {
        # machine = {
        #   network = {
        #     hostname = "${each.value.name}.${local.domain}"
        #   }
        # }
      },
      local.talos_beelink_node_config,
      "append"
    )),
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

moved {
  from = talos_machine_configuration_apply.beelink_combined["beelinknode01"]
  to   = talos_machine_configuration_apply.beelink_worker["beelinknode01"]
}

resource "talos_machine_configuration_apply" "beelink_worker" {
  for_each = {
    for index, item in local.beelink_workers :
    item.name => item
  }

  endpoint                    = each.value.address
  node                        = each.value.name
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  client_configuration        = talos_machine_secrets.secrets.client_configuration
  config_patches = [
    yamlencode(provider::deepmerge::mergo(
      {
        # machine = {
        #   network = {
        #     hostname = "${each.value.name}.${local.domain}"
        #   }
        # }
      },
      local.talos_beelink_node_config,
      "append"
    )),
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
#
# moved {
#   from = talos_machine_configuration_apply.beelink_node["beelinknode02"]
#   to   = talos_machine_configuration_apply.beelink_worker["beelinknode02"]
# }
#
# moved {
#   from = talos_machine_configuration_apply.beelink_node["beelinknode03"]
#   to   = talos_machine_configuration_apply.beelink_worker["beelinknode03"]
# }

resource "talos_machine_configuration_apply" "turingpi_combined" {
  for_each = {
    for index, item in local.turingpi_combined :
    item.name => item
  }

  endpoint                    = each.value.dhcp_address
  node                        = each.value.dhcp_address
  machine_configuration_input = data.talos_machine_configuration.combined.machine_configuration
  client_configuration        = talos_machine_secrets.secrets.client_configuration
  config_patches = [
    yamlencode(provider::deepmerge::mergo(
      {
        # machine = {
        #   network = {
        #     hostname = "${each.value.name}.${local.domain}"
        #   }
        # }
      },
      local.talos_turingpi_worker_config,
      "append"
    )),
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
    yamlencode(provider::deepmerge::mergo(
      {
        # machine = {
        #   network = {
        #     hostname = "${each.value.name}.${local.domain}"
        #   }
        # }
      },
      local.talos_turingpi_worker_config,
      "append"
    )),
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

moved {
  from = talos_machine_configuration_apply.turingpi_worker["turingnode02"]
  to   = talos_machine_configuration_apply.turingpi_combined["turingnode02"]
}

moved {
  from = talos_machine_configuration_apply.turingpi_worker["turingnode03"]
  to   = talos_machine_configuration_apply.turingpi_combined["turingnode03"]
}

moved {
  from = talos_machine_configuration_apply.turingpi_worker["turingnode04"]
  to   = talos_machine_configuration_apply.turingpi_combined["turingnode04"]
}

resource "talos_machine_bootstrap" "bootstrap" {
  depends_on           = [talos_machine_configuration_apply.beelink_combined[0]]
  node                 = tolist(local.controlplanes)[0].address
  endpoint             = tolist(local.controlplanes)[0].address
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
