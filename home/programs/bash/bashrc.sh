export PS1="\u@\h:\w\$ "

PATH_FLAKE_CONFIG="$HOME/config_flake"
PATH_SCRIPTS="$PATH_FLAKE_CONFIG/scripts"
PATH_WALLPAPERS="$PATH_FLAKE_CONFIG/wallpapers"
PATH_PROGRAMS="$PATH_FLAKE_CONFIG/home/programs"

set -o vi
source <(fzf --bash)

alias ll="ls -lF"
alias la="ls -A"
alias vi="nvim"
alias vif="nvim \$(fzf --preview='bat --color=always {}')"
alias cdf="cd \$(fd -t d | fzf)"
alias nrf="sudo nixos-rebuild switch --flake \$PATH_FLAKE_CONFIG"
alias drf="darwin-rebuild switch --flake PATH_FLAKE_CONFIG"
alias keepassxc="keepassxc -platform xcb"
alias cw="\$PATH_SCRIPTS/changeWallpaper.sh"
alias ccf="cd \$PATH_FLAKE_CONFIG"
alias rg="ranger"
alias nd="nix develop "
alias update_bashrc="cp ~/.bashrc \$PATH_FLAKE_CONFIG/home/programs/bash/bashrc.sh"
alias clean_nix="\$PATH_SCRIPTS/clean_nix.sh"
