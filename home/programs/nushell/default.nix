{ config, pkgs, ... }:
{
  programs.nushell = {
     enable = true;
     # configFile.source = $PATH_PROGRMAS/nushell/config.nu;
  };
}
