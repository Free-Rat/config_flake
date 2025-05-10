{
  config,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ./swaylock.nix
  ];

  home.packages = with pkgs; [
    swww
    # swaylock
    # swayidle # program to run a command after a certain amount of time
    # swaync
  ];

  # home.file = {
  #   ".config/sway/config" = {
  #     source = ./sway.conf;
  #   };
  # };

  # wayland.windowManager.sway = {
  #   enable = true;
  #   # config = {
  #   #   modifier = "Mod4";
  #   #   terminal = "ghostty";
  #   # };
  # };
}
