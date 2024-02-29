{ inputs, pkgs, ... }:
{
  imports = [
    ./sound.nix
    # ./hyprland.nix
    ./awesome
  ];

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

  nixpkgs = {
    config.allowUnfree = true;
#    overlays = [
#      inputs.nixvim.overlays.default
#    ];
  };

  environment.systemPackages = with pkgs; [
    #inputs.nixvim.packages.${pkgs.system}.default
    lua53Packages.luadbi
    lua53Packages.lua

    networkmanager
    networkmanagerapplet
    gcc
    clang
    xclip
    wget
    pywal
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
}
