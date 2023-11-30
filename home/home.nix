{ inputs, pkgs, user, ... }: {

  imports = [
    inputs.hyprland.homeManagerModules.default
    ./programs
  ];

  home = {
    username = "${user}";
    homeDirectory = "/home/${user}";

    sessionVariables = {
      EDITOR = "nvim";
      BROWSER = "vieb";
      TERMINAL = "alacritty";
      #GBM_BACKEND= "nvidia-drm";
      #__GLX_VENDOR_LIBRARY_NAME= "nvidia";
      #LIBVA_DRIVER_NAME= "nvidia"; # hardware acceleration
      __GL_VRR_ALLOWED = "1";
      WLR_NO_HARDWARE_CURSORS = "1";
      WLR_RENDERER_ALLOW_SOFTWARE = "1";
      CLUTTER_BACKEND = "wayland";
      WLR_RENDERER = "vulkan";

      XDG_CURRENT_DESKTOP = "Hyprland";
      XDG_SESSION_DESKTOP = "Hyprland";
      XDG_SESSION_TYPE = "wayland";
    };
  };

  home.packages = (with pkgs; [

    # User Apps
    discord
    caprine-bin
    #librewolf

    # Utils
    ranger
    wlr-randr
    curl
    dunst
    catimg
    pavucontrol
    pamixer
    light
    unzip

    # Misc 
    cava
    rofi
    nitch
    wget
    grim
    slurp
    wl-clipboard
    mpc-cli
    tty-clock
    btop

  ]) ++ (with pkgs.gnome; [
    nautilus
  ]);

  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    extraConfig = ''
      [core]
        askpass =
    '';
  };

  programs.home-manager.enable = true;

  home.stateVersion = "23.05";
}
