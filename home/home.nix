{
  inputs,
  pkgs,
  user,
  ...
}:
{
  imports = [
    # ./programs/fish.nix
    ./programs/rofi
    ./programs/nvf
    # ./programs/ghostty
    # ./programs/starship
    # ./programs/hypr
    # ./programs/river
    # ./programs/sway
    ./programs/alacritty
    ./programs/kakoune
    ./programs/wezterm
    ./programs/nushell
    # ./programs/bash
    ./programs/cava
  ];

  home = {
    username = "${user}";
    homeDirectory = "/home/${user}";
    #
    # sessionVariables = {
    #   EDITOR = "nvim";
    #   # TERMINAL = "alacritty";
    #
    #   PATH_FLAKE_CONFIG = "$HOME/config_flake";
    #   PATH_SCRIPTS = "$PATH_FLAKE_CONFIG/scripts";
    #   PATH_WALLPAPERS = "$PATH_FLAKE_CONFIG/wallpapers";
    #   PATH_PROGRAMS = "$PATH_FLAKE_CONFIG/home/programs";
    # };
  };

  home.sessionPath = [ "$HOME/.cargo/bin" ];

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
    ".local/share/icons/miku-cursor-linux" = {
      source = ../modules/hyprland/miku-cursor-linux;
    };
  };

  # ── Ensure pi global settings.json points extensions to the flake source ──
  # Uses jq to idempotently add the path without touching runtime-managed settings
  home.activation.piExtensions = ''
    SETTINGS="$HOME/.pi/agent/settings.json"
    EXTS_PATH="/home/freerat/config_flake/home/programs/pi/extensions/"

    if [ ! -f "$SETTINGS" ]; then
      mkdir -p "$(dirname "$SETTINGS")"
      echo '{}' > "$SETTINGS"
    fi

    ${pkgs.jq}/bin/jq --arg path "$EXTS_PATH" '
      if .extensions then
        if (.extensions | index($path)) then . else .extensions += [$path] end
      else .extensions = [$path] end
    ' "$SETTINGS" > "$SETTINGS.tmp" && mv "$SETTINGS.tmp" "$SETTINGS"
  '';

  xdg.configFile."niri/config.kdl".source = ../modules/niri/config.kdl;
  xdg.configFile."niri/init.sh".source = ../modules/niri/init.sh;

  home.packages = with pkgs; [
    inputs.tuxedo.packages.${pkgs.system}.default
    inputs.pi.packages.${pkgs.system}.default
    opencode
    krita
    # kicad
    tcpdump
    # kakoune
    libnotify # notify-send
    bruno
    awww
    yazi
    # User Apps
    # obsidian
    discord
    swayimg
    loupe # podgląd zdjęć
    viu # podgląd zdjęc w terminalu
    ncdu
    # caprine-bin
    # librewolf
    # nyxt
    keepassxc
    lazygit
    lazydocker
    lazyjournal
    # zathura
    maim # screenshot tool
    # xclip
    shellcheck # sh script validator

    grim
    slurp # screenshot duo

    # vieb
    # vimb
    qutebrowser
    # nyxt
    firefox
    brave
    # kitty

    signal-cli
    signal-desktop

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
    tree
    # neofetch [*]
    fastfetch
    fd # faster find

    # Misc
    fzf
    playerctl
    # rofi
    # nitch
    wget
    wl-clipboard
    mpc
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
    sshfs
  ];

  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    settings = {
      user.name = "Free-Rat";
      user.email = "lawicki02@gmail.com";
      core = {
        askpass = "";
      };
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

  programs.ssh = {
    enable = true;
    matchBlocks.hetzner = {
      host = "hetzner";
      hostname = "u555363.your-storagebox.de";
      user = "u555363";
    };
  };
}
