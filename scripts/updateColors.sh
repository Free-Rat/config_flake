#!/bin/sh
#
WALLPAPER=$(cat $PATH_WALLPAPERS/.wallpaper)

PATH_TO_COLORS="$HOME/.cache/wallust/Resized/Lab/Dark/20"
COLORS=$(ls $PATH_TO_COLORS | grep $WALLPAPER )
# echo $WALLPAPER
# echo $PATH_TO_COLORS
# echo $COLORS
wallust cs $PATH_TO_COLORS/$COLORS -q >> /dev/null
