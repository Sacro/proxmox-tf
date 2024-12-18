output "talosconfig" {
  value     = data.talos_client_configuration.client
  sensitive = true
}

output "kubeconfig" {
  value     = talos_cluster_kubeconfig.kubeconfig
  sensitive = true
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
