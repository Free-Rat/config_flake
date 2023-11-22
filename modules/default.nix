{ inputs, pkgs, ... }:

{

# programs.home-manager.enable = true;
    fonts.fonts = with pkgs; [
	noto-fonts
	    noto-fonts-cjk
	    noto-fonts-emoji
	    (nerdfonts.override { fonts = [ "Hack" "3270" ]; })

    ];

    nixpkgs.config.allowUnfree = true;

    environment.systemPackages = with pkgs; [
	neovim

#vim
	    keepassxc
#gitFull
#git
#gitui
	    unzip
	    jdk
	    lazygit
	    vieb
	    networkmanager
	    networkmanagerapplet
	    gcc
	    clang
	    xclip
	    rofi
	    awesome
	    alacritty
	    tree
	    # home-manager
	    #monaspace
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

    programs.git = {
	enable = true;
	package = pkgs.gitFull;
#config.credential.helper = "";
    };

}
