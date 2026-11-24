{ pkgs, lib, ... }:
{
  targets.darwin = {
    linkApps.enable = false;
    copyApps.enable = true;
  };

  home.packages = with pkgs; [
    signal-desktop
    nushell
    ripgrep
    codex
    firefox
    openvpn
    atac
    cmatrix
    herdr
    asciiquarium-transparent
    bash
    bash-completion
    fish
  ];

  home.activation.herdrIntegrations = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -d "$HOME/.pi/agent" ]; then
      mkdir -p "$HOME/.pi/agent/extensions"
      ${pkgs.herdr}/bin/herdr integration install pi
    fi
  '';
}
