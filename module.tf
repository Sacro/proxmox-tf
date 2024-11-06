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
