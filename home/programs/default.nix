{ config, user, ... }:
{
  imports = [
    ./alacritty
    ./dunst
    # ./hypr
    # ./kitty
    ./rofi
    # ./waybar
	../bundles/sway-bundle.nix
    ./zsh
    ./fish.nix
    ./nixvim
    ./helix
    ./cava
    ./tmux
    ./starship
  ];
}
