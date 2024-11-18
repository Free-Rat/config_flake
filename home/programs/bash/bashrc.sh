blue_c="\e[1;34m"
magenta_c="\e[1;35m"
cyan_c="\e[1;36m"
white_c="\e[1;37m"
back_c="\e[1;0m\]"
# export PS1="\[\033[1;32m\]\[\e]0;\u@\h: \w\a\]\u@\h \w >>\[\033[0m\] "
# export PS1="$cyan_c\u$white_c@$blue_c\h $magenta_c\W $cyan_c>> $back_c"
# TODO git in prompt
export PS1=" $cyan_c\W $blue_c>> $back_c"

PATH_FLAKE_CONFIG="$HOME/config_flake"
PATH_SCRIPTS="$PATH_FLAKE_CONFIG/scripts"
PATH_WALLPAPERS="$PATH_FLAKE_CONFIG/wallpapers"
PATH_PROGRAMS="$PATH_FLAKE_CONFIG/home/programs"

set -o vi
source <(fzf --bash)

# general
alias ll="ls -lF"
alias la="ls -A"
alias vi="nvim"
alias rg="ranger"

# using fzf
alias vif="nvim \$(fzf --preview='bat --color=always {}')"
alias cdf="cd \$(fd -t d | fzf)"
alias bhf="eval \$(cat ~/.bash_history | sort | uniq | fzf)"
alias open="xdg-open"
alias cw="feh --bg-fill \$(fd . -t f \$PATH_WALLPAPERS | fzf --preview='kitten icat --clear --transfer-mode=memory --stdin=no --place=\${FZF_PREVIEW_COLUMNS}x\${FZF_PREVIEW_LINES}@77x1 {} > /dev/tty' )"
# alias cw="feh --bg-fill \$PATH_WALLPAPERS/\$(ls \$PATH_WALLPAPERS | fzf --preview='chafa --fill=block \$PWD/{} 2> /dev/null' --preview-window=right:60%)"
# alias cw="\$PATH_SCRIPTS/changeWallpaper.sh"

# nix related
alias nrf="sudo nixos-rebuild switch --flake \$PATH_FLAKE_CONFIG"
alias drf="darwin-rebuild switch --flake PATH_FLAKE_CONFIG"
alias nd="nix develop "
alias ns="nix-shell -p "
alias clean_nix="\$PATH_SCRIPTS/clean_nix.sh"
alias ccf="cd \$PATH_FLAKE_CONFIG"
alias update_bashrc="cp ~/.bashrc \$PATH_FLAKE_CONFIG/home/programs/bash/bashrc.sh"

# other apps
alias keepassxc="keepassxc -platform xcb"
alias xcp="xclip -sel clip"

