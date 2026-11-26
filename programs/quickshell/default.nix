{ config, pkgs, ... }:
{
  # niri-style workspace overview, toggled with SUPER+TAB (see modules/hyprland/hyprland.lua).
  # Reads ~/.config/quickshell/overview/shell.qml.
  home.packages = [ pkgs.quickshell ];

  # Symlink to the repo (not a store copy) so quickshell hot-reloads on save —
  # edits to overview/shell.qml apply instantly, no rebuild needed.
  xdg.configFile."quickshell/overview".source =
    config.lib.file.mkOutOfStoreSymlink "/home/freerat/config_flake/programs/quickshell/overview";

  # Run as a user service so it comes back if it crashes (it once died silently,
  # leaving SUPER+TAB doing nothing). Started with the graphical session, which
  # Hyprland activates at login after importing WAYLAND_DISPLAY,
  # HYPRLAND_INSTANCE_SIGNATURE, PATH (for hyprctl) etc. into systemd.
  systemd.user.services.quickshell-overview = {
    Unit = {
      Description = "Quickshell workspace overview (SUPER+TAB)";
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session.target" ];
    };
    Service = {
      ExecStart = "${pkgs.quickshell}/bin/qs -c overview";
      Restart = "always";
      RestartSec = 1;
    };
    Install.WantedBy = [ "graphical-session.target" ];
  };
}
