{
  config,
  pkgs,
  ...
}: {
  programs.rofi = {
    enable = true;
    terminal = "alacritty";
    # theme = ./themes/squared-everforest.rasi;
    # theme = ./sniedz.rasi;
    theme = ./themes/nord.rasi;
    # package = pkgs.rofi-wayland;
    package = pkgs.rofi;
  };
}
