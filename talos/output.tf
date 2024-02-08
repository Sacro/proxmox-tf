output "talosconfig" {
  value     = data.talos_client_configuration.client.talos_config
  sensitive = true
}
