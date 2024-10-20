{imputs, ...}:{
  # home.file.".config/kitty/kitty.conf".text = builtins.readFile ./kitty.conf;
  programs.kitty = {
    enable = true;
	# shellIntegration.enableFishIntegration = true;  
	shellIntegration.enableBashIntegration = true;  
	extraConfig = builtins.readFile ./kitty.conf;
	settings = {
	 # shell = "fish";
	# background_image = "~/config_flake/wallpapers/FrenziedFlame.png";
	 # background_opacity = "0.95";
	 # background_blur = "5";
	 # background_image_layout = "cscaled";
	 # background_tint = "0.95";
	};
	# darwinLaunchOptions = [
	# 	"--single-instance"
	# 	"--directory=/tmp/my-dir"
	# 	"--listen-on=unix:/tmp/my-socket"
	# ];
  };
}
