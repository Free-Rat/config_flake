{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: {
  programs.alacritty = {
    enable = true;

    settings = {
      font = {
        #   normal = {
        #     family = "Monaspace Krypton";
        #     style = "Semibold";
        #   };
        #   italic = {
        #     family = "Monaspace Argon";
        #     style = "Medium";
        #   };
        size = 12;
      };

      # colors:
      #
      #
      colors = {
        # Default colors
        primary = {
          background = "0x000000"; # base00
          foreground = "0xffffaf"; # base05
          # cursor_text = "0x000000";
          # cursor = "0xffffaf";
        };

        # Normal colors (ANSI 0–7)
        normal = {
          black = "0x000000"; # base00
          red = "0xF7CE46"; # base08
          green = "0x7effbf"; # base0B
          yellow = "0xFAFA43"; # base0A
          blue = "0x3D8BF3"; # base0D
          magenta = "0xAB73FF"; # base0E
          cyan = "0x4AE8FA"; # base0C
          white = "0xffffaf"; # base05
        };

        # Bright colors (ANSI 8–15)
        bright = {
          black = "0x7c7c3f"; # base03
          red = "0xFAE86F"; # base09
          green = "0x041225"; # base01
          yellow = "0x163359"; # base02
          blue = "0xe1e1e1"; # base04
          magenta = "0xfafabb"; # base06
          cyan = "0xA78bf3"; # base0F
          white = "0xfafabb"; # base07
        };

        # Uncomment to make the background transparent
        # transparent_background_colors = true;
      };

      #     window = {
      #       opacity = 0.9;
      # blur = true;
      #     };

      #   padding = {
      #     x = 12;
      #     y = 12;
      #   };
    };
  };
}
