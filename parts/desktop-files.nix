{ ... }:
{
  home.file = {
    ".config/awesome".source = ../modules/awesome;
    ".config/qtile".source = ../modules/qtile;
    ".config/hypr/hyprland.conf".source = ../modules/hyprland/hyprland.conf;
    ".config/sway/Config".source = ../modules/sway/sway.conf;
    ".local/share/icons/miku-cursor-linux".source = ../modules/hyprland/miku-cursor-linux;
  };

  xdg.configFile."niri/config.kdl".source = ../modules/niri/config.kdl;
  xdg.configFile."niri/init.sh".source = ../modules/niri/init.sh;
}
