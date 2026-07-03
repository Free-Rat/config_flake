{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    settings = {
      user = {
        name = "Free-Rat";
        email = "lawicki02@gmail.com";
      };
      core.askpass = "";
    };
  };
}
