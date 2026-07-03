{ config, pkgs, ... }:
{
  programs.bash = {
    enable = true;
    # interactiveShellInit = builtins.readFile ./bashrc.sh;
    profileExtra = "source $PATH_PROGRAMS/bash/bashrc.sh";
  };

  # home.packages = with pkgs; [
  #   bash
  #   # bash-completion
  # ];
}

