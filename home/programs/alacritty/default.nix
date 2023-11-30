{ inputs, config, pkgs, lib, ... }: {
  home.packages = lib.optionals config.programs.alacritty.enable [pkgs.nerdfonts pkgs.monaspace];

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
          style = "Medium";
        };
        size = 11;
      };

      colors = {
        primary = {
          background = "#000000";
        };
        transparent_background_colors = true;
      };

      window = {
        opacity = 0.8;
      };

#   padding = {
#     x = 12;
#     y = 12;
#   };
# shell = {
#   program = "/usr/bin/env zsh";
# };
    };
  };
}
