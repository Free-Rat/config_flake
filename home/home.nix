{ inputs, pkgs, user, ...}: {

  imports = [
    inputs.hyprland.homeManagerModules.default
     ./programs
    # ./wallpapers
    # ./default.nix
  ];

  home = {
    username = "${user}";
    homeDirectory = "/home/${user}";
  };

  home.packages = (with pkgs; [
    
    # User Apps
    discord
    #librewolf

    # Utils
    ranger
    curl
    dunst
    pavucontrol
    pamixer
    light

    # Misc 
    cava
    neovim
    rofi
    nitch
    wget
    grim
    slurp
    wl-clipboard
    mpc-cli
    tty-clock
    btop

  ]) ++ (with pkgs.gnome; [ 
    nautilus
  ]);

  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    extraConfig = ''
      [core]
        askpass =
    '';
  };

  programs.home-manager.enable = true;

  home.stateVersion = "23.05";
}
