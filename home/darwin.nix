{ inputs, pkgs, hyettaUser, ... }: {

  imports = [
    # ./programs/kitty
    ./programs/wezterm
    ./programs/fish.nix
    ./programs/nixvim
    ./programs/starship
  ];
  home = {
    username = "${hyettaUser}";
    #homeDirectory = "/home/${hyettaUser}";

    sessionVariables = {
      EDITOR = "nvim";
      BROWSER = "vieb";
      TERMINAL = "kitty";
	  SHELL = "fish";

      PATH_FLAKE_CONFIG = "$HOME/config_flake";
      PATH_SCRIPTS = "$PATH_FLAKE_CONFIG/scripts";
      PATH_WALLPAPERS = "$PATH_FLAKE_CONFIG/wallpapers";
      PATH_PROGRAMS = "$PATH_FLAKE_CONFIG/home/programs";

      # KITTY_CONFIG_DIRECTORY = "$HOME/config_flake/home/programs/kitty/kitty.conf";
    };
  };


  home.packages = (with pkgs; [
    discord
    caprine-bin
    keepassxc
    kitty
    lazygit
    vieb

	dbeaver-bin
	openvpn

	bruno
	atac
	# postman

	termshark

    ranger
    curl
    catimg
    unzip
    bat
    unzip
    tree
    neofetch
    wget
    btop
	cmatrix
  ]);

  programs.home-manager.enable = true;
  programs.git = {
  	enable = true;
	package = pkgs.gitFull;
  };

  home.stateVersion = "23.05";
}