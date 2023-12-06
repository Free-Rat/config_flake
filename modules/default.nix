{ inputs, pkgs, ... }:
{
  environment.variables = {
    EDITOR = "nvim";
    SHELL = "fish";
  };

  fonts.packages = with pkgs; [
    monaspace
    noto-fonts
    noto-fonts-cjk
    noto-fonts-emoji
    (nerdfonts.override { fonts = [ "Hack" "3270" ]; })
  ];

  nixpkgs.config.allowUnfree = true;

  services.xserver = {
    layout = "pl";
    xkbVariant = "";
    enable = true;
    displayManager = {
      gdm = {
        enable = true;
        wayland = true;
      };
      # sddm.enable =true;
      # defaultSession = "none+awesome";
    };
    # windowManager.awesome = {
    # 	enable = true;
    # 	luaModules = with pkgs.luaPackages; [
    # 		luarocks
    # 		luadbi-mysql
    # 	];
    # };
  };

  programs.hyprland = {
    enable = true;
    package = inputs.hyprland.packages.${pkgs.system}.hyprland;
    xwayland.enable = true;
  };

  sound.enable = true;
  hardware.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    #jack.enable = true;
    #media-sessio.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  environment.systemPackages = with pkgs; [
    # swift
    # swiftPackages.swift-unwrapped
    # sourcekit-lsp

    jdk
    lua
    networkmanager
    networkmanagerapplet
    gcc
    clang
    xclip
    wget
  ];

  xdg.portal = {
    enable = true;
    wlr.enable = true;
  };

  services.picom = {
    enable = true;
    fade = true;
    fadeDelta = 5;
    vSync = true;
  };

  services.mpd = {
    enable = true;
  };

  systemd.user.services = {
    nm-applet = {
      description = "Network manager applet";
      wantedBy = [ "graphical-session.target" ];
      partOf = [ "graphical-session.target" ];
      serviceConfig.ExecStart = "${pkgs.networkmanagerapplet}/bin/nm-applet";
    };
  };
}
