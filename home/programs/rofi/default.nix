{ config, pkgs, ... }:
{
  programs.rofi = {
    enable = true;
    terminal = "alacritty";
    theme = ./themes/spotlight-dark-Kypton.rasi;
  };
}
