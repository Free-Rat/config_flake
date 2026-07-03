{ pkgs, ... }:
{
  targets.darwin = {
    linkApps.enable = false;
    copyApps.enable = true;
  };

  home.packages = with pkgs; [
    nushell
    ripgrep
    opencode
    firefox
    openvpn
    atac
    cmatrix
    asciiquarium-transparent
    bash
    bash-completion
  ];
}
