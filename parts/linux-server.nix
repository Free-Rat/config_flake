{ pkgs, ... }:
{
  home.sessionVariables = {
    EDITOR = "nvim";
    TERMINAL = "ghostty";

    PATH_FLAKE_CONFIG = "$HOME/config_flake";
    PATH_SCRIPTS = "$PATH_FLAKE_CONFIG/scripts";
    PATH_WALLPAPERS = "$PATH_FLAKE_CONFIG/wallpapers";
    PATH_PROGRAMS = "$PATH_FLAKE_CONFIG/programs";
  };

  home.file = {
    ".config/awesome".source = ../modules/awesome;
    ".config/qtile".source = ../modules/qtile;
  };

  home.packages = with pkgs; [
    clippy
    mpc
    slurp
    tty-clock
    wl-clipboard
  ];
}
