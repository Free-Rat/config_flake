{ config, lib, pkgs, ... }:
{
  services.nextcloud = {
    enable = true;
    hostName = "cloud.free-rat.dev";
    https = true;
    home = "/var/lib/nextcloud";

    config = {
      dbtype = "pgsql";
      dbhost = "/run/postgresql";
      dbname = "nextcloud";
      dbuser = "nextcloud";
      adminuser = "admin";

      adminpassFile = "/var/lib/nextcloud/admin-pass";
    };

    settings = {
      trusted_proxies = [ "127.0.0.1" ];
      overwriteprotocol = "https";
    };

    phpOptions = {
      "opcache.memory_consumption" = "128";
      "opcache.interned_strings_buffer" = "16";
      "opcache.max_accelerated_files" = "10000";
      "opcache.revalidate_freq" = "60";
      "memory_limit" = lib.mkForce "256M";
    };

    poolSettings = {
      "pm" = "ondemand";
      "pm.max_children" = "10";
      "pm.start_servers" = "1";
      "pm.min_spare_servers" = "1";
      "pm.max_spare_servers" = "3";
      "pm.max_requests" = "500";
    };
  };

  services.nginx.virtualHosts."cloud.free-rat.dev".listen = lib.mkForce [
    { addr = "127.0.0.1"; port = 8091; }
  ];

  services.caddy.virtualHosts."cloud.free-rat.dev".extraConfig = ''
    reverse_proxy localhost:8091
  '';

  services.postgresql = {
    enable = true;
    ensureDatabases = [ "nextcloud" ];
    ensureUsers = [
      {
        name = "nextcloud";
        ensureDBOwnership = true;
      }
    ];
  };

  systemd.services.nextcloud-setup = {
    after = [ "postgresql.service" ];
    requires = [ "postgresql.service" ];
  };

  systemd.services.nextcloud-admin-pass = {
    description = "Nextcloud admin password bootstrap";
    before = [ "nextcloud-setup.service" ];
    requiredBy = [ "nextcloud-setup.service" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };
    script = ''
      if [ ! -f "/var/lib/nextcloud/admin-pass" ]; then
        ${lib.getExe pkgs.openssl} rand -base64 48 > "/var/lib/nextcloud/admin-pass"
        echo "Admin password saved to /var/lib/nextcloud/admin-pass"
      fi
    '';
  };
}
