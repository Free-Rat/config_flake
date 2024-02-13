{ inputs, pkgs, user, ... }: {

  imports = [
    inputs.hyprland.homeManagerModules.default
    ./programs
    ./scripts
  ];

  home = {
    username = "${user}";
    homeDirectory = "/home/${user}";

    sessionVariables = {
      EDITOR = "nvim";
      BROWSER = "vieb";
      TERMINAL = "alacritty";

      PATH_FLAKE_CONFIG = "$HOME/config_flake";
      PATH_SCRIPTS = "$PATH_FLAKE_CONFIG/home/scripts";
      PATH_WALLPAPERS = "$PATH_FLAKE_CONFIG/home/wallpapers";

      QT_QPA_PLATFORM = "xcb";

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

  home.file = {
    ".config/awesome" = {
      source = ../modules/awesome;
    };
  };

  home.packages = (with pkgs; [
    # User Apps
    discord
    caprine-bin
    librewolf
    keepassxc
    alacritty
    lazygit
    vieb
    zathura

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
    jq
    bat
    unzip
    tree
    neofetch

    # Misc 
    cava
    playerctl
    rofi
    nitch
    wget
    grim
    slurp
    wl-clipboard
    mpc-cli
    tty-clock
    btop
    gh
    ueberzugpp
    xwaylandvideobridge
    rpi-imager
    feh

  ]) ++ (with pkgs.gnome; [
    nautilus
  ]);

  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    userName = "Free-Rat";
    userEmail = "lawicki02@gmail.com";
    extraConfig = ''
      [core]
        askpass =
    '';
  };

  programs.home-manager.enable = true;

  home.stateVersion = "23.05";
}
