# Blog Deployment to Talos with ArgoCD

## Prerequisites

1. Talos cluster running and accessible via `talosctl` / `kubectl`
2. ArgoCD installed on the cluster
3. This repo pushed to GitHub as `LinusThorsell/kubes`
4. nginx-ingress-controller installed
5. cert-manager installed

## Initial Cluster Setup

### 1. Install ArgoCD

```bash
kubectl create namespace argocd
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml
```

### 2. Install nginx-ingress

```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.12.1/deploy/static/provider/cloud/deploy.yaml
```

### 3. Install cert-manager

```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.17.1/cert-manager.yaml
```

### 4. Push this repo to GitHub

```bash
git remote add origin git@github.com:LinusThorsell/kubes.git
git add .
git commit -m "Add blog k8s manifests and ArgoCD apps"
git push -u origin main
```

### 5. Deploy the ArgoCD Applications

```bash
kubectl apply -f argocd/infrastructure.yaml
kubectl apply -f argocd/blog.yaml
```

### 6. Set up the blog container image

In your blog repo (`LinusThorsell/blog`), push the GitHub Actions workflow:

```bash
cd apps/blog
git add .github/workflows/build-push.yaml
git commit -m "Add container build workflow"
git push
```

The workflow will build and push `ghcr.io/linusthorsell/blog:latest` on every push to main.

Make sure the package is public or configure an image pull secret:

```bash
kubectl create secret docker-registry ghcr-secret \
  --namespace=blog \
  --docker-server=ghcr.io \
  --docker-username=LinusThorsell \
  --docker-password=<GITHUB_PAT> \
  --docker-email=admin@linusthorsell.se
```

## DNS Configuration

Point these A records to your Hetzner server IP:

| Type | Name | Value           |
|------|------|-----------------|
| A    | @    | YOUR_SERVER_IP  |
| A    | www  | YOUR_SERVER_IP  |
| A    | pb   | YOUR_SERVER_IP  |

## Architecture

```
Internet
  │
  ▼
nginx-ingress (LoadBalancer)
  │
  ├─ linusthorsell.se ──────► blog Service (port 80 → 3000)
  ├─ www.linusthorsell.se ──► blog Service (port 80 → 3000)
  └─ pb.linusthorsell.se ──► pocketbase Service (port 8090)
```

## File Structure

```
kubes/
├── argocd/
│   ├── blog.yaml              # ArgoCD Application for the blog
│   └── infrastructure.yaml    # ArgoCD Application for cluster infra
├── manifests/
│   ├── blog/
│   │   ├── namespace.yaml     # blog namespace
│   │   ├── blog-app.yaml      # SvelteKit app Deployment + Service
│   │   ├── pocketbase.yaml    # PocketBase Deployment + Service + PVC
│   │   └── ingress.yaml       # Ingress rules with TLS
│   └── infrastructure/
│       └── cert-manager-issuer.yaml  # Let's Encrypt ClusterIssuer
├── talos/                     # Talos cluster configs
└── shell.nix                  # Dev shell with tools
```

## Updating the Blog

1. Push changes to the `LinusThorsell/blog` repo
2. GitHub Actions builds and pushes a new image
3. Restart the deployment to pull the new image:

```bash
kubectl rollout restart deployment/blog -n blog
```

Or use image tags with SHA and update the manifest for fully GitOps deploys.
