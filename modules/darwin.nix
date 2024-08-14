{pkgs, ...}: {
  nixpkgs.config.allowUnfree = true;

  fonts.packages = with pkgs; [
    monaspace
    # noto-fonts
    # noto-fonts-cjk
    # noto-fonts-emoji
    # (nerdfonts.override { fonts = [ "Hack" "3270" ]; })
  ];

	# Create /etc/zshrc that loads the nix-darwin environment.
  programs = {
	  gnupg.agent.enable = true;
	  # zsh.enable = true;  # default shell on catalina
  };

  homebrew = {
	enable = true;
	casks = [
		"microsoft-teams"
		# "microsoft-outlook"
	];
  };

	# set some OSX preferences that I always end up hunting down and changing.
  system.defaults = {
	# minimal dock
	  dock = {
		  autohide = true;
		  orientation = "left";
		  show-process-indicators = false;
		  show-recents = false;
		  static-only = true;
	  };
	# a finder that tells me what I want to know and lets me work
	  finder = {
		  AppleShowAllExtensions = true;
		  ShowPathbar = true;
		  FXEnableExtensionChangeWarning = false;
	  };
  };
}
