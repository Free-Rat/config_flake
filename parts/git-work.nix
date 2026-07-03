{ pkgs, ... }:
{
  programs.git = {
    enable = true;
    package = pkgs.gitFull;
    settings.user = {
      name = "tomasz_lawicki";
      email = "tomasz.lawicki@lstsoft.com.pl";
    };
  };
}
