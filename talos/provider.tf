terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "~>0.46.1"
    }
    talos = {
      source  = "siderolabs/talos"
      version = "~>0.4.0"
    }
  }

  required_version = "1.7.3"
}

module "deepmerge-controlplane" {
  # source  = "Invicton-Labs/deepmerge/null"
  # version = "~>0.1.5"
  source = "git::https://github.com/Invicton-Labs/terraform-null-deepmerge.git?ref=af2a0dbf5a5c4cace8e4b9f422be2a8ac18f7d38" # commit hash of version 0.1.5

  maps = [
    local.talos_config,
    local.talos_controlplane_config
  ]
}

module "deepmerge-worker" {
  # source  = "Invicton-Labs/deepmerge/null"
  # version = "~>0.1.5"
  source = "git::https://github.com/Invicton-Labs/terraform-null-deepmerge.git?ref=af2a0dbf5a5c4cace8e4b9f422be2a8ac18f7d38" # commit hash of version 0.1.5

  maps = [
    local.talos_config,
    local.talos_worker_config
  ]
}
