{pkgs, ...}: {
  nixpkgs.config.allowUnfree = true;

  fonts.packages = with pkgs; [
    monaspace
    # noto-fonts
    # noto-fonts-cjk
    # noto-fonts-emoji
    # (nerdfonts.override { fonts = [ "Hack" "3270" ]; })
    # nerd-fonts.hack
    nerd-fonts.iosevka
  ];

  # Create /etc/zshrc that loads the nix-darwin environment.
  programs = {
    gnupg.agent.enable = true;
    # zsh.enable = true;  # default shell on catalina
  };

  homebrew = {
    enable = true;
    onActivation = {
      cleanup = "uninstall";
    };
    brews = [
      # 	"r"
      "mono"
      "swiftlint"
    ];

    casks = [
      # "libreoffice"
      # {
      #   name = "libreoffice";
      #   version = "25.2.4";
      #   url = "https://download.documentfoundation.org/libreoffice/stable/25.2.4/mac/aarch64/LibreOffice_25.2.4_MacOS_aarch64.dmg";
      #   # sha256 = "";
      # }
      # "cellprofiler"
      "microsoft-teams"
      "sf-symbols"
      # "raycast"
      "obsidian"
      "spotify"
      "keepassxc"
      "openvpn-connect"
      "colorpicker-materialdesign"
      # "qutebrowser"
      # "lm-studio"
      "sourcetree"
      "dbeaver-community"
      "teamviewer"
      # "microsoft-outlook"
      "bruno"
      "visual-studio-code"
      "visual-studio"
      "zoom"
      # "libreoffice-still" # nie działa ??
      "drawio"
      # "anki"
      "microsoft-remote-desktop"
      # "rstudio"
      "krita"
    ];
  };

  # Add ability to used TouchID for sudo authentication
  security.pam.services.sudo_local.touchIdAuth = true;

  # set some OSX preferences that I always end up hunting down and changing.
  system = {
    defaults = {
      # minimal dock
      dock = {
        autohide = true;
        orientation = "left";
        show-process-indicators = false;
        show-recents = false;
        static-only = true;
      };
      # a finder that tells me what I want to know and lets me work
      finder = {
        AppleShowAllExtensions = true;
        ShowPathbar = true;
        FXEnableExtensionChangeWarning = false;
      };
      loginwindow = {
        GuestEnabled = false; # disable guest user
        SHOWFULLNAME = true; # show full name in login window
      };
    };
  };
}
