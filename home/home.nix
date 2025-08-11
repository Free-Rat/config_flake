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
    ./programs/river
    # ./programs/sway
    ./programs/alacritty
    ./programs/kakoune
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
    # ".config/yambar/config.yml" = {
    #   source = ./programs/river/yambar/config.yml;
    # };
    ".config/qtile" = {
      source = ../modules/qtile;
    };
    ".config/hypr/hyprland.conf" = {
      source = ../modules/hyprland/hyprland.conf;
    };
    ".config/sway/config" = {
      source = ../modules/sway/sway.conf;
    };
  };

  xdg.configFile."niri/config.kdl".source = ../modules/niri/config.kdl;
  xdg.configFile."niri/init.sh".source = ../modules/niri/init.sh;

  home.packages = with pkgs; [
    kicad
    tcpdump
    # kakoune
    libnotify # notify-send
    bruno
    # swww
    yazi
    # User Apps
    # obsidian
    discord
    ncdu
    # caprine-bin
    librewolf
    # nyxt
    keepassxc
    lazygit
    # zathura
    maim # screenshot tool
    xclip

    vieb
    # vimb
    # qutebrowser
    # nyxt
    firefox
    brave

    kitty

    # Utils
    entr # Run arbitrary commands when files change
    pandoc # Conversion between documentation formats
    texliveSmall # TeX Live environment
    ranger
    wlr-randr
    curl
    #dunst
    catimg
    pavucontrol
    pamixer
    # light # moved to modules
    unzip
    jq
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
    # rofi
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
    gurk-rs # signal client
    feh
    acpi
    linuxquota
    # wallust
    nautilus
    obsidian
    man
    manix
    man-pages
    man-pages-posix
    libheif
    trayer
    anki-bin

    element-desktop
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
      input.method = "pipewire";
      smoothing.noise_reduction = 88;
    };
  };

  # services.trayer = {
  # enable = true;
  #   settings = {
  #     align = "right";
  #     edge = "top";
  #     height = 17;
  #     transparent = true;
  #     tint = "#000000";
  #     width = 5;
  #     widthtype = "request";
  #     SetDockType = true;
  #     SetPartialStrut = true;
  #     expand = true;
  #   };
  # };
  # services.network-manager-applet.enable = true;

  programs.home-manager.enable = true;

  home.stateVersion = "23.05";
}
