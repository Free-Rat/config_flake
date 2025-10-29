{
  inputs,
  pkgs,
  ...
}: {
  # hyprland cachix
  # nix.settings = {
  #   substituters = ["https://hyprland.cachix.org"];
  #   trusted-public-keys = ["hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="];
  # };

  services.greetd = {
    enable = true;
    settings = {
      default_session = {
        command = "${pkgs.hyprland}/bin/hyprland -c /home/freerat/config_flake/modules/hyprland/hyprland.conf";
        user = "freerat";
      };
    };
  };

  services = {
    xserver = {
      xkb.layout = "pl";
      xkb.variant = "";
      enable = true;
    };
    displayManager = {
      gdm = {
        enable = true;
        wayland = true;
      };
    };
  };

  programs.hyprland = {
    enable = true;
    xwayland.enable = true;
    # withUWSM = true;

    # set the flake package
    # package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
    # make sure to also set the portal package, so that they are in sync
    # portalPackage = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
  };
}
