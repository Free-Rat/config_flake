{ inputs, pkgs, user, ... }: {

  imports = [
    # inputs.hyprland.homeManagerModules.default
	# ./programs/fish.nix
	./programs/rofi
	./programs/nixvim
	# ./programs/starship
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

      QT_QPA_PLATFORM = "xcb";

	  # KITTY_CONFIG_DIRECTORY = "$HOME/config_flake/home/programs/kitty/kitty.conf";
    };
  };

  home.sessionPath = [ "$HOME/.cargo/bin" ];

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

  home.packages = (with pkgs; [
    # User Apps
	# obsidian
    discord
	ncdu
    # caprine-bin
    # librewolf
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
	# wallust
	nautilus
	# youtrack
  # ]) 
  # ++ (with pkgs.gnome; [
  #   nautilus
  ]);

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
