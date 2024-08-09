{ config, lib, pkgs,  ... }:

let
	bundle-set = (import ../../bundles/wayland-pakgs-bundle.nix pkgs);
	# extra-pkgs = (bundle-set pkgs).extra;
in
{
	imports = [ 
		./waybar
		./yambar
		./swaylock.nix
	];

	home.packages = (with pkgs; [
		waybar
		brightnessctl
		swww
	]) ++ bundle-set;

	wayland.windowManager.river = {
		enable = true;
		extraConfig = builtins.readFile ./config.sh;
		# settings = {
		# 	border-width = 2;
		# 	declare-mode = [
		# 		"locked"
		# 		"normal"
		# 		"passthrough"
		# 	];
		# 	map = {
		# 		normal = {
		# 			"Super Q" = "close";
		# 			"Super+Shift Q" = "close";
		#
		# 			"Super J" = "focus-view next";
		# 			"Super K" = "focus-view previous";
		# 			"Super+Shift J" = "swap next";
		# 			"Super+Shift K" = "swap previous";
		#
		# 			"Super+Control J" = "focus output next";
		# 			"Super+Control K" = "focus output previous";
		# 			"Super+Control+Shift J" = "send-to-output next";
		# 			"Super+Control+Shift K" = "send-to-output previous";
		#
		# 			"Super Return" = "spawn alacritty";
		#
		# 			"Super b" = "spawn firefox";
		#
		# 			"Super Space" = "'spawn rofi -show drun'";
		# 		};
		# 	};
		# 	spawn = [
		# 		"rivertile"
		# 		"waybar"
		# 		"swww init"
		# 		"sww img /home/freerat/config_flake/home/wallpapers/ranni1.jpg"
		# 		"'foot -a terminal'"
		# 	];
		# 	set = {
		# 		mod = "Mod4";
		# 		terminal = "foot";
		# 	};
		# };
		# # keyboard-layout = "pl";
		# extraConfig = ''
		# 	riverctl output-layout rivertile
		# '';
		# extraSessionVariables = {};
	};
}
