{
  config,
  lib,
  pkgs,
  ...
}:
# let
#   # bundle-set = (import ../../bundles/wayland-pakgs-bundle.nix pkgs);
#   # extra-pkgs = (bundle-set pkgs).extra;
# in
{
  imports = [
    ./swaylock.nix
  ];

  home.packages = with pkgs; [
    brightnessctl
    eww
    # swww
  ];
  # ]) ++ bundle-set;

  wayland.windowManager.river = {
    enable = true;
    extraConfig = builtins.readFile ./config.sh;
    xwayland.enable = true;
  };
}
