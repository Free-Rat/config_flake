{imputs, ...}:{
  # home.file.".config/kitty/kitty.conf".text = builtins.readFile ./kitty.conf;
  programs.wezterm = {
    enable = true;
	extraConfig = builtins.readFile ./wezterm.lua;
  };
}
