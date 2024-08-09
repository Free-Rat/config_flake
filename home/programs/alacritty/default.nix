{ inputs, config, pkgs, lib, ... }: {
  home.packages = lib.optionals config.programs.alacritty.enable [ pkgs.nerdfonts pkgs.monaspace ];

  programs.alacritty = {
    enable = true;

    settings = {
      # import = [
      #   "${pkgs.vimPlugins.nightfox-nvim}/extra/carbonfox/nightfox_alacritty.yml"
      # ];

      env = {
        SHELL = "fish";
      };

      font = {
        normal = {
          family = "Monaspace Krypton";
          style = "Semibold";
        };
        italic = {
          family = "Monaspace Argon";
          style = "Medium";
        };
        # size = 12;
        size = 9;
      };

      colors = {
        primary = {
          background = "#000000";
        };
        transparent_background_colors = true;
      };

      window = {
        opacity = 0.9;
		blur = true;
      };

      #   padding = {
      #     x = 12;
      #     y = 12;
      #   };
      shell = {
	  	program = "${pkgs.fish}/bin/fish";
	  	# program = "/bin/sh";
		args = [
			# "-c"
			# "-init-command"
			# "--init-command=bash -c $PATH_SCRIPTS/updateColors.sh"
			# "--command=tmux"
			# "bash -c $PATH_SCRIPTS/changeWallpaper.sh && exec fish"

		];
      };
    };
  };
}
