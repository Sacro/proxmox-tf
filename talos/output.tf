output "talosconfig" {
  value     = data.talos_client_configuration.client
  sensitive = true
}

output "kubeconfig" {
  value     = data.talos_cluster_kubeconfig.kubeconfig
  sensitive = true
}

output "proxmox-controlplane-image" {
  value     = data.talos_image_factory_urls.proxmox-controlplane.urls
  sensitive = false
}

output "proxmox-worker-image" {
  value     = data.talos_image_factory_urls.proxmox-worker.urls.disk_image
  sensitive = false
}
