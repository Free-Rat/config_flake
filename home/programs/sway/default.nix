{ config, lib, pkgs, ... }: {
 
 	imports = [
		./waybar
	];

	home.packages = with pkgs; [
		waybar
		swww
		swaylock
	];

	wayland.windowManager.sway = {
		enable = true;
		config = {
			modifier = "Mod4";
			terminal = "alacritty";
		};
	};
}
