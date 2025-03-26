{
  inputs,
  pkgs,
  user,
  ...
}: {
  imports = [
    # ./programs/fish.nix
    ./programs/rofi
    # ./programs/nixvim
    ./programs/nvf
    ./programs/ghostty
    # ./programs/starship
    # ./programs/hypr
  ];

  home = {
    username = "${user}";
    homeDirectory = "/home/${user}";

    sessionVariables = {
      EDITOR = "nvim";
      BROWSER = "vieb";
      # TERMINAL = "alacritty";
      TERMINAL = "kitty";

      PATH_FLAKE_CONFIG = "$HOME/config_flake";
      PATH_SCRIPTS = "$PATH_FLAKE_CONFIG/scripts";
      PATH_WALLPAPERS = "$PATH_FLAKE_CONFIG/wallpapers";
      PATH_PROGRAMS = "$PATH_FLAKE_CONFIG/home/programs";
    };
  };

  home.sessionPath = ["$HOME/.cargo/bin"];

  home.file = {
    ".config/awesome" = {
      source = ../modules/awesome;
    };
    ".config/yambar/config.yml" = {
      source = ./programs/river/yambar/config.yml;
    };
    ".config/qtile" = {
      source = ../modules/qtile;
    };
    ".config/hypr/hyprland.conf" = {
      source = ../modules/hyprland/hyprland.conf;
    };
  };

  home.packages = with pkgs; [
    swww
    yazi
    # User Apps
    # obsidian
    discord
    ncdu
    # caprine-bin
    librewolf
    nyxt
    keepassxc
    lazygit
    # zathura
    maim # screenshot tool
    xclip

    # vieb
    # vimb
    # qutebrowser
    nyxt
    firefox
    kitty

    # Utils
    ranger
    wlr-randr
    curl
    dunst
    catimg
    pavucontrol
    pamixer
    # light # moved to modules
    unzip
    # jq
    bat
    unzip
    tree
    neofetch
    fastfetch
    fd # faster find

    # Misc
    fzf
    cava
    playerctl
    rofi
    # nitch
    wget
    slurp
    wl-clipboard
    mpc-cli
    tty-clock
    btop
    # gh
    # ueberzugpp
    # rpi-imager
    feh
    acpi
    linuxquota
    wallust
    nautilus
    obsidian
    man
    manix
    man-pages
    man-pages-posix
    # libsecret
    # youtrack
    clippy
    # ])
    # ++ (with pkgs.gnome; [
    #   nautilus
  ];

  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    userName = "Free-Rat";
    userEmail = "lawicki02@gmail.com";
    extraConfig = {
      core = {
        askpass = "";
      };
    };
  };

  programs.cava = {
    enable = true;
    settings = {
      general.framerate = 60;
      input.method = "alsa";
      smoothing.noise_reduction = 88;
    };
  };

  programs.home-manager.enable = true;

  home.stateVersion = "23.05";
}
