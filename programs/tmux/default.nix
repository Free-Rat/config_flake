{ config, user, inputs, pkgs, ... }: {
  programs.tmux = {
    enable = true;
    historyLimit = 10000;
    keyMode = "vi";
    shell = "${pkgs.fish}/bin/fish";
    terminal = "alacritty";
	escapeTime = 0;
  };
}
