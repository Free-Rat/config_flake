{ config, pkgs, ... }:
{
  programs.bash = {
    enable = true;
    interactiveShellInit = builtins.readFile ./bashrc.sh;
  };

  home.packages = with pkgs; [
    bash
    bash-completion
  ];
}

