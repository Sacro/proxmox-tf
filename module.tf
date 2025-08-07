module "talos" {
  source             = ".//talos"
  github_org         = var.github_org
  github_repository  = var.github_repository
  github_token       = var.github_token
  harbor_robot_token = var.harbor_robot_token
  proxmox_endpoint   = var.proxmox_endpoint
  proxmox_password   = var.proxmox_password
  proxmox_token      = var.proxmox_token
  proxmox_username   = var.proxmox_username
}

output "talosconfig" {
  value     = module.talos.talosconfig
  sensitive = true
}

output "proxmox-control-plane-installer-url" {
  value = module.talos.proxmox-control-plane-installer-url
}

output "proxmox-worker-installer-url" {
  value = module.talos.proxmox-worker-installer-url
}

output "turingpi-worker-installer-url" {
  value = module.talos.turingpi-worker-installer-url
}

output "talos_client_configuration" {
  value     = module.talos.talos_client_configuration
  sensitive = true
}

output "talos_machine_secrets" {
  value     = module.talos.talos_machine_secrets
  sensitive = true
}
