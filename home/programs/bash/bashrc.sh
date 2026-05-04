#!/bin/bash

# Reset
back_c="\[\e[1;0m\]"
reset_c="\[\033[0m\]"

# Regular colors
black_c="\[\033[0;30m\]"
red_c="\[\033[0;31m\]"
green_c="\[\033[0;32m\]"
yellow_c="\[\033[0;33m\]"
blue_c="\[\033[0;34m\]"
magenta_c="\[\033[0;35m\]"
cyan_c="\[\033[0;36m\]"
white_d_c="\[\033[0;37m\]"

# Bright (bold) colors
black_l_c="\[\033[1;30m\]"
red_l_c="\[\033[1;31m\]"
green_l_c="\[\033[1;32m\]"
yellow_l_c="\[\033[1;33m\]"
blue_l_c="\[\033[1;34m\]"
magenta_l_c="\[\033[1;35m\]"
cyan_l_c="\[\033[1;36m\]"
white_l_c="\[\033[1;37m\]"

# Optional: background colors
bg_black_c="\[\033[40m\]"
bg_red_c="\[\033[41m\]"
bg_green_c="\[\033[42m\]"
bg_yellow_c="\[\033[43m\]"
bg_blue_c="\[\033[44m\]"
bg_magenta_c="\[\033[45m\]"
bg_cyan_c="\[\033[46m\]"
bg_white_c="\[\033[47m\]"

# export PS1="\[\033[1;32m\]\[\e]0;\u@\h: \w\a\]\u@\h \w >>\[\033[0m\] "
# export PS1="$cyan_c\u$white_c@$blue_c\h $magenta_c\W $cyan_c>> $back_c"
# TODO git in prompt
# TODO vim mode
# TODO nix-shell

# Get hostname
HOST=$(hostname)


# Change color depending on hostname
case "$HOST" in
    maliketh)
        COLOR=$black_l_c
        ;;
    malenia)
        COLOR=$red_l_c
        ;;
    ranni)
        COLOR=$cyan_l_c
        ;;
    melina)
        COLOR=$magenta_l_c
        ;;
    MacBookAir.home)
        COLOR=$yellow_l_c
        ;;
    MacBook-Air-Tomasz.local)
        COLOR=$yellow_l_c
        ;;
    *)
        COLOR=$green_c
        ;;
esac

# Set PS1
export PS1="\n ${COLOR}\W $white_d_c>$white_l_c> $back_c ${reset_c}"

PATH_FLAKE_CONFIG="$HOME/config_flake"
PATH_SCRIPTS="$PATH_FLAKE_CONFIG/scripts"
PATH_WALLPAPERS="$PATH_FLAKE_CONFIG/wallpapers"
PATH_PROGRAMS="$PATH_FLAKE_CONFIG/home/programs"
PATH="$PATH:$HOME/.cargo/bin"
PATH="/home/freerat/.local/bin:$PATH"

EDITOR="nvim"

set -o vi
source <(fzf --bash)

# general
alias ll="ls -lF --color=always"
alias la="ls -A"
alias vi="nvim"
alias rg="ranger"

# using fzf
alias vif="nvim \$(fzf --preview='bat --color=always {}')"
alias cdf="cd \$(fd -t d | fzf)"
alias bhf="eval \$(cat ~/.bash_history | sort | uniq | fzf)"
alias open="xdg-open"
# alias cw="feh --bg-fill \$(fd . -t f \$PATH_WALLPAPERS | fzf --preview='kitten icat --clear --transfer-mode=memory --stdin=no --place=\${FZF_PREVIEW_COLUMNS}x\${FZF_PREVIEW_LINES}@77x1 {} > /dev/tty' )"
alias cw="\$PATH_SCRIPTS/changeWallpaper.sh"

# nix related
alias nrf="sudo nixos-rebuild switch --flake \$PATH_FLAKE_CONFIG"
alias drf="sudo darwin-rebuild switch --flake \$PATH_FLAKE_CONFIG"
alias nd="nix develop "
alias ns="nix-shell -p "
alias clean_nix="\$PATH_SCRIPTS/clean_nix.sh"
alias ccf="cd \$PATH_FLAKE_CONFIG"
alias update_bashrc="cp ~/.bashrc \$PATH_FLAKE_CONFIG/home/programs/bash/bashrc.sh"

# other apps
alias keepassxc="keepassxc -platform xcb"
alias copy="xclip -sel clip"

# work
alias ccw="cd ~/work"
alias ccp="cd ~/projects"

# wallust run $(cat ~/.wallpaper_path) -I background -q -C $PATH_PROGRAMS/wallust.toml -u

# unlimited Bash history
export HISTSIZE=-1
export HISTFILESIZE=-1
# Ensure Bash appends to history instead of overwriting across sessions
shopt -s histappend
# This skips duplicate commands and those starting with a space
export HISTCONTROL=ignoreboth:erasedups
