{ config, lib, pkgs, ... }:
{
  services.vaultwarden = {
    enable = true;

    # Enables the module's own backup-vaultwarden service + timer. It runs
    # `sqlite3 db.sqlite3 ".backup ..."` as the vaultwarden user — the SQLite
    # online backup API, which is the only correct way to copy a live WAL
    # database — then copies everything except db.* (RSA keys, attachments,
    # sends, config.json). Must not live inside the data dir; the module
    # asserts that, and creates this path 0770 vaultwarden:vaultwarden.
    #
    # The timer defaults to 23:00 daily (OnCalendar is mkDefault, so override
    # systemd.timers.backup-vaultwarden.timerConfig.OnCalendar to change it).
    # This only refreshes the staging copy; snapshot it with
    # scripts/backup.sh to get history, and scripts/vaultwarden-backup-now.sh
    # does both plus verification in one go.
    backupDir = "/var/backup/vaultwarden";

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
