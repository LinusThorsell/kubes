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
    echo "Talos / Hetzner / Argo CD shell loaded"
    echo ""
    echo "Available tools:"
    echo "  hcloud   - Hetzner Cloud CLI"
    echo "  talosctl - Talos Linux CLI"
    echo "  kubectl  - Kubernetes CLI"
    echo "  argocd   - Argo CD CLI"
    echo ""
    echo "Remember to set:"
    echo "  export HCLOUD_TOKEN=..."
  '';
}
