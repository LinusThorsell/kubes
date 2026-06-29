{ pkgs ? import <nixpkgs> {
    config.allowUnfreePredicate = pkg:
      builtins.elem (pkg.pname or (builtins.parseDrvName pkg.name).name) [
        "terraform"
      ];
  }
}:

pkgs.mkShell {
  packages = with pkgs; [
    hcloud
    talosctl
    kubectl
    argocd
    terraform
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

    export KUBECONFIG="$PWD/terraform/kubeconfig"
    export TALOSCONFIG="$PWD/terraform/talosconfig"

    echo "Talos / Hetzner / Argo CD shell loaded"
    echo ""
    echo "Available tools:"
    echo "  hcloud    - Hetzner Cloud CLI"
    echo "  talosctl  - Talos Linux CLI"
    echo "  kubectl   - Kubernetes CLI"
    echo "  argocd    - Argo CD CLI"
    echo "  terraform - Infrastructure as Code"
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
