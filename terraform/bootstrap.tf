resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true
  atomic           = true
  timeout          = 600

  depends_on = [
    module.talos,
    local_file.kubeconfig
  ]
}

resource "helm_release" "hcloud_csi" {
  name             = "hcloud-csi"
  repository       = "https://charts.hetzner.cloud"
  chart            = "hcloud-csi"
  namespace        = "kube-system"
  create_namespace = false
  atomic           = true
  timeout          = 600

  set = [
    {
      name  = "controller.hcloudVolumeDefaultLocation"
      value = var.location_name
    }
  ]

  set_sensitive = [
    {
      name  = "controller.hcloudToken.value"
      value = var.hcloud_token
    }
  ]

  depends_on = [
    module.talos,
    local_file.kubeconfig
  ]
}

resource "kubectl_manifest" "argocd_root" {
  yaml_body = file("${path.module}/../argocd/root.yaml")

  depends_on = [
    helm_release.argocd,
    helm_release.hcloud_csi
  ]
}
