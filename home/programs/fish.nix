{ inputs, config, pkgs, ... }: {

  programs.fish = {
    enable = true;

    shellAliases = {
      nrf = "sudo nixos-rebuild switch --flake .";
      keepassxc = "keepassxc -platform xcb";
    };

    plugins = [
      { name = "grc"; src = pkgs.fishPlugins.grc.src; }
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
