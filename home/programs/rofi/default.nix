{ config, pkgs, ... }:
{
  programs.rofi = {
    enable = true;
    terminal = "alacritty";
    # theme = ./theme.rasi;
  };
}
