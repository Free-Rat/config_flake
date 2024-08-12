#!/bin/sh
#

# Get random image from directory

# WALLPAPER=$(ls $PATH_WALLPAPERS | shuf -n 1)

current_wallpaper=$(cat $PATH_WALLPAPERS/.wallpaper)
wallpaper=$(ls $PATH_WALLPAPERS | grep -v $current_wallpaper | shuf -n 1)

# Set WALLPAPER
# swww img $PATH_WALLPAPERS/$wallpaper
feh --bg-fill $PATH_WALLPAPERS/$wallpaper
# wallust run $PATH_WALLPAPERS/$wallpaper -q

touch $PATH_WALLPAPERS/.wallpaper
echo $wallpaper > $PATH_WALLPAPERS/.wallpaper

# get colors from wallust json file 
# PATH_TO_COLORS="$HOME/.cache/wallust/Resized/Lab/Dark/20"
# COLORS=$(ls $PATH_TO_COLORS | grep $WALLPAPER )

# json_data=$(cat $PATH_TO_COLORS/$COLORS)

# inject them to scss waybar file
# scss_file="$PATH_WALLPAPERS/.colors.scss"
# echo "" > $scss_file

# echo "$json_data" | jq -r 'to_entries[] | "//$\(."key")\n$\(."key"): rgb(\(."value"[0]), \(."value"[1]), \(."value"[2]));"' | sed 's/rgb/rgba/g' >> "$scss_file"

# echo "$json_data" | jq -r 'to_entries[] | "//$\(."key")\n$\(."key"): rgba(\(."value"[0]), \(."value"[1]), \(."value"[2]), 1);"' >> "$scss_file"

# cp $scss_file $PATH_FLAKE_CONFIG/home/programs/river/waybar/colors.scss

# complete the waybar scss file

# inject css file to .config/waybar/config.css

# "reload" waybar


#use colors to set rofi colors

