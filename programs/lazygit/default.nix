{
  config,
  user,
  inputs,
  pkgs,
  ...
}:
{
  programs.lazygit = {
    enable = true;
    settings = {
      git.autoFetch = false;
    };
  };
}
