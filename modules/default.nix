{
  inputs,
  pkgs,
  lib,
  config,
  ...
}: {
  imports = [
    ./sound.nix
  ];

  environment.variables = {
    EDITOR = "nvim";
    SHELL = "bash";
    KITTY_CONFIG_DIRECTORY = "/home/freerat/config_flake/home/programs/kitty";
    PATH_FLAKE_CONFIG = "$HOME/config_flake";
    PATH_SCRIPTS = "$PATH_FLAKE_CONFIG/scripts";
    PATH_WALLPAPERS = "$PATH_FLAKE_CONFIG/wallpapers";
    PATH_PROGRAMS = "$PATH_FLAKE_CONFIG/home/programs";
  };

  fonts.packages = with pkgs; [
    monaspace
    #    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji
  ];

  nixpkgs = {
    config.allowUnfree = true;
  };

  environment.systemPackages = with pkgs; [
    inputs.fabric-bar.packages.${pkgs.system}.default

    # xorg.xbacklight
    brightnessctl
    picom

    # elixir

    # swift
    # swiftpm
    # swiftPackages.Foundation

    # zig

    rustc
    cargo

    lua
    networkmanager
    networkmanagerapplet
    # gcc
    clang
    wget

    # qmk
    # keymapviz

    # libimobiledevice # 4:iOS mounting
    # ifuse # 4:iOS mounting
  ];
  # services.usbmuxd.enable = true; # 4:iOS mounting

  systemd.user.services = {
    nm-applet = {
      description = "Network manager applet";
      wantedBy = ["graphical-session.target"];
      partOf = ["graphical-session.target"];
      serviceConfig.ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet";
    };
  };

  services.openssh.enable = true;
  # programs.light.enable = true;
}
