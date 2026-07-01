# Admin UIs over Tailscale

This repo installs the Tailscale Kubernetes Operator and exposes PocketBase
and Argo CD admin access through admin-only tailnet endpoints.

## One-time Tailscale setup

1. Add tag ownership and an explicit admin-only ACL in the Tailscale policy:

```json
{
  "acls": [
    {
      "action": "accept",
      "src": ["autogroup:admin"],
      "dst": ["tag:k8s:*"]
    }
  ],
  "tagOwners": {
    "tag:k8s-operator": ["autogroup:admin"],
    "tag:k8s": ["tag:k8s-operator"]
  }
}
```

Do not keep the default allow-all rule:

```json
{
  "action": "accept",
  "src": ["*"],
  "dst": ["*:*"]
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
forwards all paths on that private tailnet hostname to PocketBase. Check the
resulting tailnet endpoint with:

```sh
kubectl get ingress -n blog pocketbase-admin
```

Access the admin UI over Tailscale with the MagicDNS name shown in the ingress
status, usually:

```txt
https://pocketbase-admin.<tailnet-name>.ts.net/_/
```

Public `https://pb.linusthorsell.se/_/` is blocked by the nginx
`pocketbase-admin-public-deny` ingress. The public `_superusers` API prefix is
blocked the same way. Keep using `pb.linusthorsell.se` for the public PocketBase
API.

The tailnet ingress intentionally forwards `/`, not only `/_/`. PocketBase's
admin UI is loaded from `/_/`, but it calls API endpoints on the same host, such
as `/api/collections/_superusers/...`. Access to this private hostname is
restricted by the tailnet ACL above, so it is treated as an admin-only endpoint
rather than a public API path.

Using the exact public hostname `pb.linusthorsell.se` for the admin UI requires
a custom tailnet DNS/reverse-proxy setup. The Tailscale Kubernetes Operator
ingress host must be a tailnet endpoint name, not the public custom domain.

The ingress rule host must match `spec.tls.hosts[0]`; otherwise the Tailscale
operator rejects the backend as unsupported.

## Accessing Argo CD

The `argocd` ingress in the `argocd` namespace exposes the existing
`argocd-server` service over Tailscale using the same L7 ingress pattern as
PocketBase admin.

Check the resulting tailnet endpoint with:

```sh
kubectl get ingress -n argocd argocd
```

Access Argo CD over Tailscale with the MagicDNS name shown in the service
status, usually:

```txt
https://argocd.<tailnet-name>.ts.net
```
