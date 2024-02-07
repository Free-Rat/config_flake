{ pkgs, config, ... }: {

  services.xserver = {
    enable = true;
    layout = "pl";
    xkbVariant = "";
    displayManager = {
      lightdm.greeters.mini = {
        enable = true;
        user = "freerat";
        extraConfig = ''
          [greeter]
          show-password-label = false
          password-alignment = center
          [greeter-theme]
          background-image = "/etc/lightdm/wallpapers/ranni5.jpg"
          font = "MonaspaceKrypton"
          background-color = "#000000"
          window-color = "#000000"
          border-color = "#000000"
        '';
      };
      defaultSession = "none+dwm";
    };
  };

  services.xserver.windowManager.dwm.enable = true;
  services.xserver.windowManager.dwm.package = pkgs.dwm.override {
    conf = ./config.def.h;
    # patches = [
    #   # for local patch files, replace with relative path to patch file
    #   ./path/to/local.patch
    #
    #   # for external patches
    #   (pkgs.fetchpatch {
    #     # replace with actual URL
    #     url = "https://dwm.suckless.org/patches/path/to/patch.diff";
    #     # replace hash with the value from `nix-prefetch-url "https://dwm.suckless.org/patches/path/to/patch.diff" | xargs nix hash to-sri --type sha256`
    #     # or just leave it blank, rebuild, and use the hash value from the error
    #     hash = "";
    #   })
    #
    #   src = ./path/to/dwm/source/tree;
    # ];
  };

  services.picom = {
    enable = true;
    fade = true;
    fadeDelta = 5;
    vSync = true;
  };
}
