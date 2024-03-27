{ config, user, ... }:
{
  imports = [
    ./alacritty
    ./dunst
    # ./kitty
    ./rofi
	# ../bundles/sway-bundle.nix
	# ../bundles/hypr-bundle.nix
	./hypr
    ./zsh
    ./fish.nix
    ./nixvim
    ./helix
    ./cava
    ./tmux
    ./starship
  ];
}
