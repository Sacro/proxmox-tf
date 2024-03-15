module "deepmerge-controlplane-proxmox" {
  # source  = "Invicton-Labs/deepmerge/null"
  # version = "~>0.1.5"
  source = "git::https://github.com/Invicton-Labs/terraform-null-deepmerge.git?ref=af2a0dbf5a5c4cace8e4b9f422be2a8ac18f7d38" # commit hash of version 0.1.5

  maps = [
    local.talos_config,
    local.talos_proxmox_config,
    local.talos_controlplane_config
  ]
}

module "deepmerge-worker-proxmox" {
  # source  = "Invicton-Labs/deepmerge/null"
  # version = "~>0.1.5"
  source = "git::https://github.com/Invicton-Labs/terraform-null-deepmerge.git?ref=af2a0dbf5a5c4cace8e4b9f422be2a8ac18f7d38" # commit hash of version 0.1.5

  maps = [
    local.talos_config,
    local.talos_proxmox_config,
    local.talos_proxmox_worker_config,
    local.talos_worker_config
  ]
}

module "deepmerge-worker-turingpi" {
  # source  = "Invicton-Labs/deepmerge/null"
  # version = "~>0.1.5"
  source = "git::https://github.com/Invicton-Labs/terraform-null-deepmerge.git?ref=af2a0dbf5a5c4cace8e4b9f422be2a8ac18f7d38" # commit hash of version 0.1.5

  maps = [
    local.talos_config,
    local.talos_turingpi_config,
    local.talos_worker_config
  ]
}
