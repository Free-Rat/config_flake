# export PS1="\u@\h:\w\ -> "
# \n\[\033[1;32m\][\[\e]0;\u@\h: \w\a\]\u@\h:\w]\$\[\033[0m\]

# Function to calculate the padding
# Function to calculate padding and print username@hostname on the right
# Set PS1 with dynamic right alignment for user@hostname

# elo="xd"
# PS1='\[\033[0;35m\]\u@\h\[\033[0m\] \w\n$elo -> '
# PS1='\[\033[0;35m\]Kocham \[\033[0m\] Pimpki -> '

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

