{ inputs, config, pkgs, ... }: {

  programs.fish = {
    enable = true;

    shellAliases = {
      nrf = "sudo nixos-rebuild switch --flake .";
      keepassxc = "keepassxc -platform xcb";

	  cw = "bash $PATH_SCRIPTS/changeWallpaper.sh";
	  ccf = "cd $PATH_FLAKE_CONFIG";

      vi = "nvim";
      vim = "nvim";

	  rg = "ranger";

      nd = "nix develop . --command fish";
	  nd-j = "nix develop ~/nixDevShells/java/ --command fish";
	  nd-p = "nix develop ~/nixDevShells/python/ --command fish";
	  nd-c = "nix develop ~/nixDevShells/c --command fish";
	  nd-sw = "nix develop ~/nixDevShells/swift --command fish";
	  nd-w = "nix develop ~/nixDevShells/web --command fish";

	  txk = "tmux kill-session";
    };

    interactiveShellInit = ''set fish_greeting ""'';

    plugins = [
      # { name = "grc"; src = pkgs.fishPlugins.grc.src; }
      # {
      #   name = "slavic-cat";
      #   src = pkgs.fetchFromGitHub {
      #     owner = "oh-my-fish";
      #     repo = "omf-theme-slavic-cat";
      #     rev = "ec39d2e244952ad3324202eccacc5299c9fa7618";
      #     hash = "8ab85a22f2e9c0eedd4eaa1d0f184404aa4e8fb3";
      #   };
      # }
    ];

  };

}
