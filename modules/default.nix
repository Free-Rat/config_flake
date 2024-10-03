{ inputs, pkgs, lib, config, ... }:
{
  imports = [
    ./sound.nix
    # ./hyprland.nix
    # ./awesome
	# if options.useHyprland = true then ./hyprland.nix else ./awesome.nix;
	# lib.mkIf config.useHyprland ./hyprland.nix ./awesome.nix
	# ./sway.nix
  ];

  environment.variables = {
    EDITOR = "nvim";
    SHELL = "fish";
	KITTY_CONFIG_DIRECTORY = "/home/freerat/config_flake/home/programs/kitty";
  };

  fonts.packages = with pkgs; [
    monaspace
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    (nerdfonts.override { fonts = [ "Hack" "3270" ]; })
  ];

  nixpkgs = {
    config.allowUnfree = true;
  };

  environment.systemPackages = with pkgs; [
  	# xorg.xbacklight
	brightnessctl

	elixir

	swift
	swiftpm
	swiftPackages.Foundation

	zig

	rustc
	cargo

	lua
    networkmanager
    networkmanagerapplet
    gcc
    clang
    wget

	qmk
	keymapviz
  ];

  systemd.user.services = {
    nm-applet = {
      description = "Network manager applet";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig.ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet";
    };
  };

  services.openssh.enable = true;

  hardware.keyboard.qmk.enable = true;
  services.udev.packages = [ 
  	pkgs.via
	pkgs.qmk-udev-rules
  ]; 
  programs.light.enable = true;
}
