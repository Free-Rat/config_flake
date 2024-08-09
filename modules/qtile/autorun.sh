#!/bin/sh

#kitty

run() {
    if ! pgrep -f "$1"; then
        "$@" &
    fi
}
run "kitty --config /home/freerat/config_flake/home/programs/kitty/kitty.conf"
# run "volumeicon"

run "nm-applet"
run "picom" -b
run "feh --bg-fill $HOME/config_flake/home/wallpapers/ranni1.jpg"
