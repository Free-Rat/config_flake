{ config, lib, pkgs, ... }:
{
  services.forgejo = {
    enable = true;

    settings = {
      server = {
        DOMAIN = "git.free-rat.dev";
        ROOT_URL = "https://git.free-rat.dev/";
        HTTP_ADDR = "127.0.0.1";
        HTTP_PORT = 3000;
        DISABLE_SSH = true;
        LFS_START_SERVER = true;
      };

      session = {
        COOKIE_SECURE = true;
      };

      security = {
        INSTALL_LOCK = true;
      };

      service = {
        DISABLE_REGISTRATION = true;
      };

      DEFAULT = {
        RUN_MODE = "prod";
      };
    };

    lfs = {
      enable = true;
    };
  };

  services.caddy.virtualHosts."git.free-rat.dev".extraConfig = ''
    reverse_proxy localhost:3000
  '';
}
