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
        size = 20;
      };

      # colors:
      #
      #
      colors = {
        #   # Default colors
        #   primary:
        #     background: '0x000000'
        #     foreground: '0x00fb92'
        primary = {
          background = "0x000000";
          foreground = "0x00fb92";
        };
        #   # Normal colors
        #   normal:
        #     black:   '0x000000'
        #     red:     '0xfb056b'
        #     green:   '0x20fc03'
        #     yellow:  '0xfae300'
        #     blue:    '0x0321fe'
        #     magenta: '0xff01c2'
        #     cyan:    '0x01f6f6'
        #     white:   '0xf1f0fb'
        normal = {
          black = "0x090909";
          red = "0xfb056b";
          green = "0x20fc03";
          yellow = "0xfae300";
          blue = "0x0321fe";
          magenta = "0xff01c2";
          cyan = "0x01f6f6";
          white = "0xf1f0fb";
        };
        #   # Bright colors
        #   bright:
        #     black:   '0x000000'
        #     red:     '0xfb056b'
        #     green:   '0x20fc03'
        #     yellow:  '0xfae300'
        #     blue:    '0x0321fe'
        #     magenta: '0xff01c2'
        #     cyan:    '0x01f6f6'
        #     white:   '0xf1f0fb'
        bright = {
          black = "0x090909";
          red = "0xfb056b";
          green = "0x20fc03";
          yellow = "0xfae300";
          blue = "0x0321fe";
          magenta = "0xff01c2";
          cyan = "0x01f6f6";
          white = "0xf1f0fb";
        };
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
