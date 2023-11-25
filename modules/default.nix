{ inputs, pkgs, ... }:
{
    fonts.packages = with pkgs; [
	monaspace
	noto-fonts
	    noto-fonts-cjk
	    noto-fonts-emoji
	    (nerdfonts.override { fonts = [ "Hack" "3270" ]; })
    ];

    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [
	neovim
	bat
	lua
	keepassxc
	unzip
	lazygit
	vieb
	networkmanager
	networkmanagerapplet
	gcc
	clang
	xclip
	alacritty
	tree
	wget
    ];

    services.picom = {
	enable = true;
	fade = true;
	fadeDelta = 5;
	vSync = true;
    };

    systemd.user.services = {
	nm-applet = {
	    description = "Network manager applet";
	    wantedBy = ["graphical-session.target"];
	    partOf = ["graphical-session.target"];
	    serviceConfig.ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet";
	};
    };
}
