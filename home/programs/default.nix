{ config, user, ... }:
{
  imports = [
    ./alacritty
    ./dunst
    ./hypr
    ./kitty
    ./rofi
    ./waybar
    ./zsh
    ./fish.nix
    ./nixvim
    ./helix
    ./cava
    ./tmux
    ./starship
  ];
}
