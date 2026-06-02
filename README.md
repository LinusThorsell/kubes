# kubes

Kubernetes infrastructure for a single-node Talos cluster on Hetzner Cloud, managed with ArgoCD.

## Structure

```
kubes/
├── argocd/            # ArgoCD Application definitions
├── manifests/
│   ├── blog/          # Blog app + PocketBase
│   └── infrastructure/# Cluster-level resources (cert-manager issuer)
├── talos/             # Talos machine configs
└── shell.nix          # Dev shell (hcloud, talosctl, kubectl, argocd)
```

## Apps

| App | Domain | Image |
|-----|--------|-------|
| Blog (SvelteKit) | linusthorsell.se | ghcr.io/linusthorsell/blog |
| PocketBase | pb.linusthorsell.se | ghcr.io/muchobien/pocketbase |

## Deployment

Pushes to the [blog repo](https://github.com/LinusThorsell/blog) build a new container image and update the manifest here automatically. ArgoCD syncs changes from this repo to the cluster.

## Prerequisites

- [Talos](https://www.talos.dev/) cluster
- ArgoCD
- Hetzner CSI driver
- cert-manager
- ingress-nginx (hostNetwork)
