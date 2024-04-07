#!/bin/sh
#

# Get random image from directory

WALLPAPER=$(ls $PATH_WALLPAPERS | shuf -n 1)

# Set WALLPAPER
swww img $PATH_WALLPAPERS/$WALLPAPER
wallust run $PATH_WALLPAPERS/$WALLPAPER

#TODO: get wallrust colors

#use colors for waybar

#use colors to set alacritty colors

#use colors to set rofi colors

