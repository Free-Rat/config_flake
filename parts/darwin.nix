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
    opencode
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

  home.activation.herdrOpenCodeIntegration = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -d "$HOME/.config/opencode" ]; then
      ${pkgs.herdr}/bin/herdr integration install opencode
    fi
    ${pkgs.herdr}/bin/herdr integration install pi
  '';
}
