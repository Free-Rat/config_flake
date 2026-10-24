{ config, lib, pkgs, ... }:
{
  # Nextcloud 33 removed services.nextcloud.config.adminuser/adminpassFile. The
  # admin account already exists from the original install; its generated
  # password is still at /var/lib/nextcloud/admin-pass. Further users:
  #   nextcloud-occ user:add <name> && nextcloud-occ group:adduser admin <name>
  services.nextcloud = {
    enable = true;
    # Bump ONE major at a time, and only after the previous one has finished
    # migrating — Nextcloud refuses upgrades across multiple majors, and the
    # migration is not undone by rolling back the NixOS generation.
    # Use scripts/nextcloud-upgrade-step.sh, which checks that and backs up first.
    # Available in the pinned nixpkgs: 33.0.10, 34.0.5, 35.0.2.
    package = pkgs.nextcloud35;
    hostName = "cloud.free-rat.dev";
    https = true;
    home = "/var/lib/nextcloud";

    config = {
      dbtype = "pgsql";
      dbhost = "/run/postgresql";
      dbname = "nextcloud";
      dbuser = "nextcloud";
    };

    settings = {
      trusted_proxies = [ "127.0.0.1" ];
      overwriteprotocol = "https";
      maintenance_window_start = 1; # 1 a.m.
      default_phone_region = "PL";
      log_type = "file";
      logfile = "/var/log/nextcloud/nextcloud.log";
    };

    phpOptions = {
      "opcache.memory_consumption" = "128";
      "opcache.interned_strings_buffer" = "16";
      "opcache.max_accelerated_files" = "10000";
      "opcache.revalidate_freq" = "60";
      "memory_limit" = lib.mkForce "512M";
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
}
