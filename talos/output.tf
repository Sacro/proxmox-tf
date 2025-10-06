output "talosconfig" {
  value     = data.talos_client_configuration.client
  sensitive = true
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.kubeconfig
  sensitive = true
}

# Installer URLs

output "hyperv-worker-installer-url" {
  value = data.talos_image_factory_urls.hyperv-worker.urls.installer
}

output "proxmox-control-plane-installer-url" {
  value = data.talos_image_factory_urls.proxmox-controlplane.urls.installer
}

output "proxmox-worker-installer-url" {
  value = data.talos_image_factory_urls.proxmox-worker.urls.installer
}

output "turingpi-worker-installer-url" {
  value = data.talos_image_factory_urls.turingpi-worker.urls.installer
}

# Secrets

output "talos_client_configuration" {
  value     = talos_machine_secrets.secrets.client_configuration
  sensitive = true
}

output "talos_machine_secrets" {
  value     = talos_machine_secrets.secrets.machine_secrets
  sensitive = true
}
