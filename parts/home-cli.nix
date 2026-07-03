{ pkgs, lib, ... }:
{
  home.packages =
    with pkgs;
    [
      bat
      btop
      catimg
      curl
      fastfetch
      fd
      fzf
      lazygit
      ncdu
      ranger
      tree
      unzip
      wget
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      linuxquota
      man
      man-pages
      man-pages-posix
      manix
    ];
}
