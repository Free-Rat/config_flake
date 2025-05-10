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

  programs.sway = {
    enable = true;
    xwayland.enable = true;
  };

  security.pam.services.swaylock = {};
}
