{ config, pkgs, ... }:
{
    programs = {
        zsh = {
            enable = true;
            oh-my-zsh = {
                enable = true;
                theme = "refined";
                plugins = [
                    "git"
                ];
            };

            enableAutosuggestions = true;
            enableCompletion = true;
            # enableSyntaxHighlighting = true;
	    syntaxHighlighting.enable = true;
        };
    };

    home.file.".zshrc".text = ''
export PATH=$HOME/bin:/usr/local/bin:$PATH

# Rofi
export PATH=$HOME/.config/rofi/scripts:$PATH
export PATH=$PATH:~/Apps
    '';
}
