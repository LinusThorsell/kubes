variable "hcloud_token" {
  type        = string
  description = "Hetzner Cloud API token for the new, isolated project. Do not use the production project token."
  sensitive   = true
}

variable "cluster_name" {
  type        = string
  description = "Name used for Hetzner Cloud resources."
  default     = "kubes"
}

variable "location_name" {
  type        = string
  description = "Hetzner Cloud location for the new cluster."
  default     = "hel1"
}

variable "control_plane_type" {
  type        = string
  description = "Hetzner Cloud server type for the single schedulable control-plane node."
  default     = "cpx22"
}

variable "talos_version" {
  type        = string
  description = "Talos version used for the generated machine configs and custom Hetzner image."
  default     = "v1.12.2"
}

variable "kubernetes_version" {
  type        = string
  description = "Kubernetes version for initial cluster creation."
  default     = "1.35.0"
}

variable "cilium_version" {
  type        = string
  description = "Cilium version bootstrapped by Terraform."
  default     = "1.18.5"
}

variable "enable_ipv6" {
  type        = bool
  description = "Enable IPv6 on Hetzner resources and add ::/0 to public web firewall rules."
  default     = true
}

variable "firewall_admin_source_ips" {
  type        = list(string)
  description = "CIDR source ranges allowed to reach the Kubernetes and Talos APIs. Defaults to the current public IPv4 /32."
  default     = null
}
