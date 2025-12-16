{
  inputs,
  pkgs,
  user,
  ...
}: {
  imports = [
    # ./programs/fish.nix
    # ./programs/nixvim
    ./programs/nvf
    ./programs/ghostty
    # ./programs/starship
  ];

  home = {
    username = "${user}";
    homeDirectory = "/home/${user}";

    sessionVariables = {
      EDITOR = "nvim";
      # TERMINAL = "alacritty";
      TERMINAL = "ghostty";

      PATH_FLAKE_CONFIG = "$HOME/config_flake";
      PATH_SCRIPTS = "$PATH_FLAKE_CONFIG/scripts";
      PATH_WALLPAPERS = "$PATH_FLAKE_CONFIG/wallpapers";
      PATH_PROGRAMS = "$PATH_FLAKE_CONFIG/home/programs";
    };
  };

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
  };

  home.packages = with pkgs; [
    # User Apps
    ncdu
    lazygit
    ranger
    wlr-randr
    curl
    catimg
    unzip
    # jq
    bat
    unzip
    tree
    fastfetch
    fd # faster find
    fzf
    wget
    slurp
    wl-clipboard
    mpc
    tty-clock
    btop
    linuxquota
    man
    manix
    man-pages
    man-pages-posix
    clippy
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

  programs.home-manager.enable = true;

  home.stateVersion = "23.05";
}
