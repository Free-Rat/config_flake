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

  xdg.portal.enable = true;

  programs.river-classic = {
    enable = true;
    extraPackages = with pkgs; [
      # grim
      ristate
    ];
  };
}
