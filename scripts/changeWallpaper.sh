#!/bin/sh

wallpaper=$(fd . -t f $PATH_WALLPAPERS | fzf --preview="kitten icat --clear --transfer-mode=memory --stdin=no --place=\${FZF_PREVIEW_COLUMNS}x\${FZF_PREVIEW_LINES}@77x1 {} > /dev/tty")

# feh --bg-fill $wallpaper
swww img $wallpaper

wallust run $wallpaper -q -I background -C $PATH_PROGRAMS/wallust.toml

echo $wallpaper >~/.wallpaper_path
