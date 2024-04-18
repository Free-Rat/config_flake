{ config, pkgs, ... }:
{
  programs = {
    zsh = {
      enable = true;
      oh-my-zsh = {
        enable = true;
        theme = "fishy"; #refined
        plugins = [
          "git"
          "emoji"
          "emotty"
          # "zsh-vi-mode"

        ];
      };
      defaultKeymap = "viins";
      autosuggestion.enable = true;
      enableCompletion = true;
      syntaxHighlighting.enable = true;
    };
  };

  home.file.".zshrc".text = ''

    '';
}
