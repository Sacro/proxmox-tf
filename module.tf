module "talos" {
  source = ".//talos"
}

output "talosconfig" {
  value     = module.talos.talosconfig
  sensitive = true
}
