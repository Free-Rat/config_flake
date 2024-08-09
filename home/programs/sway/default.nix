{ config, lib, pkgs, ... }: {
 
 	imports = [
		# ./waybar
	];

	home.packages = with pkgs; [
		# waybar
		swww
		swaylock
		# swayidle # program to run a command after a certain amount of time
		# swaync
	];

	wayland.windowManager.sway = {
		enable = true;
		config = {
			modifier = "Mod4";
			terminal = "alacritty";

		};
	};
}
