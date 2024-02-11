#!/bin/sh

#kitty

run() {
    if ! pgrep -f "$1"; then
        "$@" &
    fi
}
run "kitty"
run "volumeicon"
run "nm-applet"
run "picom" -b
