# Terraform Talos Cluster

This directory is for the new Hetzner project only. It uses `hcloud-talos/talos/hcloud` and creates a single schedulable Talos control-plane node.

## First Decisions

- `hcloud_token`: use a token from the new Hetzner project, not the current production project.
- `location_name`: default is `hel1`; change it before apply if you want another Hetzner location.
- `control_plane_type`: default is `cpx22`; adjust before apply if the single node needs more CPU or memory.
- `enable_ipv6`: default is `true` so public web services can be reached over IPv6 when DNS has AAAA records.
- `firewall_admin_source_ips`: optional CIDR list for Kubernetes and Talos API access. If omitted, Terraform discovers the current public IPv4 address and allows only that `/32`.

## Commands

```sh
cd terraform
cp terraform.tfvars.example terraform.tfvars
$EDITOR terraform.tfvars
nix-shell --run 'cd terraform && terraform init'
nix-shell --run 'cd terraform && terraform plan'
```

After apply:

```sh
nix-shell --run 'cd terraform && terraform output --raw kubeconfig > ./kubeconfig'
nix-shell --run 'cd terraform && terraform output --raw talosconfig > ./talosconfig'
```

## Follow-up Bootstrap Work

Terraform now bootstraps the minimum cluster services needed to hand control to GitOps:

- Argo CD from the `argo-cd` Helm chart.
- Hetzner CSI from the `hcloud-csi` Helm chart, using the same new-project Hetzner token.
- The existing root Argo CD Application from `../argocd/root.yaml`.

Argo CD then manages the rest of this repository. The current Kubernetes manifests still expect these cluster services:

- Argo CD for the app-of-apps flow in `argocd/root.yaml`.
- cert-manager before applying `manifests/infrastructure/cert-manager-issuer.yaml`.
- ingress-nginx with `hostNetwork` as defined in `argocd/ingress-nginx.yaml`.
- Hetzner CSI driver because `manifests/blog/pocketbase.yaml` uses `storageClassName: hcloud-volumes`.

cert-manager is installed as an Argo CD Application with an earlier sync wave than `infrastructure`. If the `ClusterIssuer` races the cert-manager CRDs during the first sync, Argo CD self-heal should converge it on the next retry.
