{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: {
   home.packages = lib.optionals config.programs.alacritty.enable [pkgs.nerdfonts pkgs.monaspace];

  programs.alacritty = {
    enable = true;

    settings = {
      # import = [
      #   "${pkgs.vimPlugins.nightfox-nvim}/extra/carbonfox/nightfox_alacritty.yml"
      # ];

      font = {
        normal = {
          family = "Monaspace Krypton";
          style = "Medium";
        };
        size = 11;
      };
      #
      # window = {
      #   padding = {
      #     x = 12;
      #     y = 12;
      #   };
      # };
      # shell = {
      #   program = "/usr/bin/env zsh";
      # };
    };
  };
}
