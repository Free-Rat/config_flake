#!/bin/sh

# wallpaper=$(fd . -t f $PATH_WALLPAPERS | fzf --preview="kitten icat --clear --transfer-mode=memory --stdin=no --place=\${FZF_PREVIEW_COLUMNS}x\${FZF_PREVIEW_LINES}@77x1 {} > /dev/tty")
wallpaper=$(
    fd . -t f $PATH_WALLPAPERS |
    fzf --preview='sh -c '\''viu -w 80 -h 24 "$1"'\'' _ {}'
    # fzf --preview='wezterm imgcat --no-move-cursor --resize 800x600 {} > /dev/tty'
    # fzf --preview='sh -c '\''script -q /dev/null -c "wezterm imgcat --no-move-cursor --resize 800x600 \"$1\"" 2>/dev/null'\'' _ {}'
    # fzf --preview='sh -c '\''wezterm imgcat --no-move-cursor --resize 800x600 "$1" < /dev/null > /dev/tty 2>/dev/null'\'' _ {}'
)

# feh --bg-fill $wallpaper
swww img $wallpaper

wallust run $wallpaper -q -I background -C $PATH_PROGRAMS/wallust.toml

echo $wallpaper >~/.wallpaper_path
