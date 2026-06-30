# PocketBase admin over Tailscale

This repo installs the Tailscale Kubernetes Operator and exposes only the
PocketBase admin UI path (`/_/`) through a tailnet ingress.

## One-time Tailscale setup

1. Add tag ownership in the Tailscale ACL policy:

```json
{
  "tagOwners": {
    "tag:k8s-operator": ["autogroup:admin"],
    "tag:k8s": ["tag:k8s-operator"]
  }
}
```

2. Create an OAuth client in the Tailscale admin console.
3. Give it permission to create/manage devices and allow it to use
   `tag:k8s-operator`.
4. Copy the OAuth client ID and client secret. The secret is only shown once.
5. Before Argo CD syncs the operator, create the operator secret:

```sh
kubectl create namespace tailscale
kubectl create secret generic operator-oauth \
  --namespace tailscale \
  --from-literal=client_id="$TAILSCALE_OAUTH_CLIENT_ID" \
  --from-literal=client_secret="$TAILSCALE_OAUTH_CLIENT_SECRET"
```

If the namespace already exists, use this idempotent form instead:

```sh
kubectl create namespace tailscale --dry-run=client -o yaml | kubectl apply -f -
kubectl create secret generic operator-oauth \
  --namespace tailscale \
  --from-literal=client_id="$TAILSCALE_OAUTH_CLIENT_ID" \
  --from-literal=client_secret="$TAILSCALE_OAUTH_CLIENT_SECRET" \
  --dry-run=client -o yaml | kubectl apply -f -
```

Argo CD installs the operator from the official Tailscale Helm chart in
`argocd/tailscale-operator.yaml`.

## Accessing the admin UI

The Tailscale operator will reconcile the `pocketbase-admin` ingress in the
`blog` namespace. It creates a tailnet endpoint named `pocketbase-admin` and
only forwards the PocketBase admin UI path (`/_/`). Check the resulting tailnet
endpoint with:

```sh
kubectl get ingress -n blog pocketbase-admin
```

Access the admin UI over Tailscale with the MagicDNS name shown in the ingress
status, usually:

```txt
https://pocketbase-admin.<tailnet-name>.ts.net/_/
```

Public `https://pb.linusthorsell.se/_/` is blocked by the nginx
`pocketbase-admin-public-deny` ingress. Keep using `pb.linusthorsell.se` for the
public PocketBase API.

Using the exact public hostname `pb.linusthorsell.se` for the admin UI requires
a custom tailnet DNS/reverse-proxy setup. The Tailscale Kubernetes Operator
ingress host must be a tailnet endpoint name, not the public custom domain.
