{
  config,
  pkgs,
  ...
}: {
  programs.rofi = {
    enable = true;
    terminal = "alacritty";
    theme = ./themes/squared-everforest.rasi;
  };
}
