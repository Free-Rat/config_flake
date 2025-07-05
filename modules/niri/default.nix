{
  inputs,
  pkgs,
  ...
}: {
  services.xserver = {
    xkb.layout = "pl";
    xkb.variant = "";
    enable = true;
    displayManager = {
      gdm = {
        enable = true;
        wayland = true;
      };
    };
  };

  programs.niri = {
    enable = true;
    # xwayland.enable = true;
    # set the flake package
    # package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
  };
  programs.xwayland.enable = true;

  xdg.portal = {
    enable = true;
    wlr.enable = true;
  };
}
