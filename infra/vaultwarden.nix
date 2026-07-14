{ config, lib, pkgs, ... }:
{
  services.vaultwarden = {
    enable = true;

    config = {
      DOMAIN = "https://vault.free-rat.dev";
      ROCKET_ADDRESS = "127.0.0.1";
      ROCKET_PORT = 8222;
      SIGNUPS_ALLOWED = false;
      SIGNUPS_VERIFY = true;
      ROCKET_LOG = "critical";
    };

    environmentFile = [
      "/var/lib/vaultwarden/admin-token"
    ];
  };

  services.caddy.virtualHosts."vault.free-rat.dev".extraConfig = ''
    handle /notifications/hub {
      reverse_proxy localhost:8222
    }
    handle {
      reverse_proxy localhost:8222
    }
  '';

  systemd.tmpfiles.rules = [
    "d /var/lib/vaultwarden 0700 vaultwarden vaultwarden - -"
  ];

  systemd.services.vaultwarden-admin-token = {
    description = "Vaultwarden admin token bootstrap";
    before = [ "vaultwarden.service" ];
    requiredBy = [ "vaultwarden.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "vaultwarden";
      Group = "vaultwarden";
    };
    script = ''
      if [ ! -f "/var/lib/vaultwarden/admin-token" ]; then
        echo -n "ADMIN_TOKEN=" > "/var/lib/vaultwarden/admin-token"
        ${lib.getExe pkgs.openssl} rand -base64 48 >> "/var/lib/vaultwarden/admin-token"
      fi
    '';
  };
}
