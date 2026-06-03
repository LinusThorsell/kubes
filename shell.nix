{ pkgs ? import <nixpkgs> {} }:

pkgs.mkShell {
  packages = with pkgs; [
    hcloud
    talosctl
    kubectl
    argocd
    jq
    curl
    xz
    openssh
  ];

  shellHook = ''
    if [ -f .env ]; then
      set -a
      source .env
      set +a
    fi

    export TALOSCONFIG="$PWD/talos/talosconfig"
    export KUBECONFIG="$PWD/talos/kubeconfig"

    echo "Talos / Hetzner / Argo CD shell loaded"
    echo ""
    echo "Available tools:"
    echo "  hcloud   - Hetzner Cloud CLI"
    echo "  talosctl - Talos Linux CLI"
    echo "  kubectl  - Kubernetes CLI"
    echo "  argocd   - Argo CD CLI"
    echo ""

    if [ -z "''${HCLOUD_TOKEN:-}" ]; then
      echo "⚠ HCLOUD_TOKEN not set — add it to .env"
    fi

    if [ ! -f "$TALOSCONFIG" ]; then
      echo "⚠ talosconfig not found at $TALOSCONFIG"
    fi

    if [ ! -f "$KUBECONFIG" ]; then
      echo "⚠ kubeconfig not found at $KUBECONFIG"
    fi
  '';
}
