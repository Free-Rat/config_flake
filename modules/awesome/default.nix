{ inputs, pkgs, ... }: {
	services = {
		xserver = {
			xkb.layout = "pl";
			xkb.variant = "";
			enable = true;
			displayManager = {
				lightdm.greeters.mini = {
					enable = true;
					user = "freerat";
					extraConfig = ''
[greeter]
show-password-label = false
password-alignment = center
[greeter-theme]
background-image = "/home/freerat/config_flake/home/wallpapers/ranni5.jpg"
font = "MonaspaceKrypton"
background-color = "#000000"
window-color = "#000000"
border-color = "#000000"
					'';
				};
			};
			windowManager.awesome = {
				enable = true;
				luaModules = with pkgs.luaPackages; [
					#luarocks
					#luadbi-mysql
				];
			};
		};
		displayManager.defaultSession = "none+awesome";
	};

	# services.picom = {
	# 	enable = true;
	# 	fade = true;
	# 	fadeDelta = 5;
	# 	vSync = true;
	# 	settings = {
	# 		blur = {
	# 			method = "dual_kawase";
	# 			strength = 3;
	# 			background-exclude = {
	# 				window_type = "dock";
	# 				class_g = "Awesome";
	# 			};
	# 		};
	# 	};
	# };
}
