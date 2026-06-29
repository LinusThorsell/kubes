output "public_ipv4_list" {
  description = "Public IPv4 addresses of the control-plane nodes."
  value       = module.talos.public_ipv4_list
}

output "kubeconfig" {
  description = "Generated kubeconfig. Export with: terraform output --raw kubeconfig > ./kubeconfig"
  value       = module.talos.kubeconfig
  sensitive   = true
}

output "talosconfig" {
  description = "Generated talosconfig. Export with: terraform output --raw talosconfig > ./talosconfig"
  value       = module.talos.talosconfig
  sensitive   = true
}
