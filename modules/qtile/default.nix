{ inputs, pkgs, ... }: {
  services = {
  xserver = {
    xkb.layout = "pl";
    xkb.variant = "";
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
    };
    windowManager.qtile = {
      enable = true;
	  # configFile = ./config.py; # whole directory is copied to ~/.config/qtile, defined in ../home/home.nix
	  extraPackages = python3Packages: with python3Packages; [
		  qtile-extras
	  ];
	};
    };
  displayManager.defaultSession = "qtile";
  };

  services.picom = {
    enable = true;
    fade = true;
    fadeDelta = 5;
    vSync = true;
  };
}
