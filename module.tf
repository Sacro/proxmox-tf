module "talos" {
  source            = ".//talos"
  github_org        = var.github_org
  github_repository = var.github_repository
  github_token      = var.github_token
}

output "talosconfig" {
  value     = module.talos.talosconfig
  sensitive = true
}

output "proxmox-controlplane-image" {
  value     = module.talos.proxmox-controlplane-image
  sensitive = false
}

output "proxmox-worker-image" {
  value     = module.talos.proxmox-worker-image
  sensitive = false
}
