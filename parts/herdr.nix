{ pkgs, lib, ... }:
{
  home.packages = [ pkgs.herdr ];

  home.activation.herdrIntegrations = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -d "$HOME/.config/opencode" ]; then
      ${pkgs.herdr}/bin/herdr integration install opencode
    fi
    if [ -d "$HOME/.pi" ]; then
      mkdir -p "$HOME/.pi/agent/extensions"
      ${pkgs.herdr}/bin/herdr integration install pi
    fi
    ${pkgs.herdr}/bin/herdr integration install claude
  '';
}
