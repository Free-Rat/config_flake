#!/bin/sh -e

# Enable XWayland support
# xwayland-satellite :0 &

# Lock idle session
# swayidle -w \
#     timeout 600 swaylock \
#     before-sleep swaylock &

# Screen dimming
# wlsunset &

# Make sure the screenshots directory exists
# mkdir -p "${XDG_PICTURES_DIR}/Screenshots"

# Start wallpaper manager
# set +e
# swww-daemon --no-cache &
# swww img -t none ~/.config/wallpaper
# set -e

# Fix screen capture
# Source: https://github.com/emersion/xdg-desktop-portal-wlr/wiki/%22It-doesn't-work%22-Troubleshooting-Checklist
# Import the WAYLAND_DISPLAY env var from sway into the systemd user session.
# dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP=river
# Stop any services that are running, so that they receive the new env var when they restart.
# systemctl --user stop pipewire wireplumber xdg-desktop-portal xdg-desktop-portal-wlr
# systemctl --user start wireplumber

# Start the status bar
# yambar &

# Start on workspace 1 (index 6)
# niri msg action focus-workspace 6

# Run custom autostart, if present
# [ -f ~/.config/autostart.sh ] && . ~/.config/autostart.sh
