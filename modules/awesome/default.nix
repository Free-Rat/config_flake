{ inputs, pkgs, ... }:
{
  services.xserver = {
    layout = "pl";
    xkbVariant = "";
    enable = true;
    displayManager = {
      lightdm.greeters.mini = {
        enable = true;
        user = "freerat";
        extraConfig = ''
          [greeter]
          show-password-label = false
          password-alignment = center
          [greeter-theme]
          background-image = "/home/freerat/config_flake/home/wallpapers/ranni5.jpg"
          font = "MonaspaceKrypton"
          background-color = "#000000"
          window-color = "#000000"
          border-color = "#000000"
        '';
      };
      defaultSession = "none+awesome";
    };
    windowManager.awesome = {
      enable = true;
      luaModules = with pkgs.luaPackages; [
        #luarocks
        #luadbi-mysql
      ];
    };
  };

  services.picom = {
    enable = true;
    fade = true;
    fadeDelta = 5;
    vSync = true;
  };
}
