terraform {
  required_version = ">= 1.10.0"

  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = "1.66.0"
    }

    imager = {
      source  = "hcloud-talos/imager"
      version = "1.0.15"
    }

    helm = {
      source  = "hashicorp/helm"
      version = "3.2.0"
    }

    kubectl = {
      source  = "alekc/kubectl"
      version = "2.4.1"
    }

    local = {
      source  = "hashicorp/local"
      version = "2.9.0"
    }

    talos = {
      source  = "siderolabs/talos"
      version = "0.11.0"
    }

    http = {
      source  = "hashicorp/http"
      version = "3.6.0"
    }
  }
}

provider "hcloud" {
  token = var.hcloud_token
}

provider "imager" {
  token = var.hcloud_token
}

provider "talos" {}

provider "helm" {
  kubernetes = {
    host                   = module.talos.kubeconfig_data.host
    client_certificate     = module.talos.kubeconfig_data.client_certificate
    client_key             = module.talos.kubeconfig_data.client_key
    cluster_ca_certificate = module.talos.kubeconfig_data.cluster_ca_certificate
  }
}

provider "kubectl" {
  host                   = module.talos.kubeconfig_data.host
  client_certificate     = module.talos.kubeconfig_data.client_certificate
  client_key             = module.talos.kubeconfig_data.client_key
  cluster_ca_certificate = module.talos.kubeconfig_data.cluster_ca_certificate
  load_config_file       = false
  lazy_load              = true
  apply_retry_count      = 3
}

resource "talos_image_factory_schematic" "x86" {
  schematic = yamlencode({
    customization = {
      systemExtensions = {
        officialExtensions = []
      }
    }
  })
}

data "talos_image_factory_urls" "hcloud_amd64" {
  talos_version = var.talos_version
  schematic_id  = talos_image_factory_schematic.x86.id
  platform      = "hcloud"
  architecture  = "amd64"
}

resource "imager_image" "talos_x86" {
  image_url    = data.talos_image_factory_urls.hcloud_amd64.urls.disk_image
  architecture = "x86"
  description  = "Talos Linux ${var.talos_version} x86 ${var.cluster_name}"

  labels = {
    cluster = var.cluster_name
    version = var.talos_version
  }
}

data "http" "personal_ipv4" {
  count = var.firewall_admin_source_ips == null ? 1 : 0
  url   = "https://ipv4.icanhazip.com"

  retry {
    attempts     = 3
    min_delay_ms = 1000
    max_delay_ms = 2000
  }
}

locals {
  public_web_source_ips = var.enable_ipv6 ? ["0.0.0.0/0", "::/0"] : ["0.0.0.0/0"]
  firewall_admin_sources = (
    var.firewall_admin_source_ips != null
    ? var.firewall_admin_source_ips
    : ["${chomp(data.http.personal_ipv4[0].response_body)}/32"]
  )
}

module "talos" {
  source = "git::https://github.com/hcloud-talos/terraform-hcloud-talos.git?ref=v3.4.11"

  hcloud_token = var.hcloud_token

  cluster_name = var.cluster_name

  location_name      = var.location_name
  talos_version      = var.talos_version
  kubernetes_version = var.kubernetes_version
  cilium_version     = var.cilium_version

  talos_image_id_x86 = imager_image.talos_x86.id
  disable_x86        = true
  disable_arm        = true
  enable_ipv6        = var.enable_ipv6

  firewall_kube_api_source  = local.firewall_admin_sources
  firewall_talos_api_source = local.firewall_admin_sources
  extra_firewall_rules = [
    {
      description = "Allow public HTTP ingress"
      direction   = "in"
      protocol    = "tcp"
      port        = "80"
      source_ips  = local.public_web_source_ips
    },
    {
      description = "Allow public HTTPS ingress"
      direction   = "in"
      protocol    = "tcp"
      port        = "443"
      source_ips  = local.public_web_source_ips
    }
  ]

  enable_alias_ip            = true
  enable_floating_ip         = false
  kubeconfig_endpoint_mode   = "public_ip"
  talosconfig_endpoints_mode = "public_ip"

  control_plane_allow_schedule = true
  control_plane_nodes = [
    {
      id   = 1
      type = var.control_plane_type
    }
  ]

  worker_nodes = []

  deploy_cilium                   = true
  deploy_hcloud_ccm               = true
  deploy_prometheus_operator_crds = false
  disable_talos_coredns           = false
}

resource "local_file" "kubeconfig" {
  filename        = "${path.module}/kubeconfig"
  content         = module.talos.kubeconfig
  file_permission = "0600"
}
