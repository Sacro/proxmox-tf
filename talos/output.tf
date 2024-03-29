output "talosconfig" {
  value     = data.talos_client_configuration.client
  sensitive = true
}

output "kubeconfig" {
  value     = data.talos_cluster_kubeconfig.kubeconfig
  sensitive = true
}
