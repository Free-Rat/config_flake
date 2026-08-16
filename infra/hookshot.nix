{ config, lib, pkgs, ... }:
# currently not used - dead code 
# but it will be used in the future probably so it stays
let
  domain = "free-rat.dev";
  registrationFile = "/var/lib/matrix-hookshot/registration.yml";
in
{
  services.matrix-hookshot = {
    enable = true;

    registrationFile = registrationFile;

    settings = {
      passFile = "/var/lib/matrix-hookshot/passkey.pem";

      bridge = {
        domain = domain;
        url = "http://localhost:6167";
        mediaUrl = "https://matrix.${domain}";
        port = 9993;
        bindAddress = "127.0.0.1";
      };

      logging = {
        level = "info";
      };

      listeners = [
        {
          port = 9000;
          bindAddress = "127.0.0.1";
          resources = [ "webhooks" ];
        }
      ];

      generic = {
        enabled = true;
        urlPrefix = "https://hooks.${domain}/webhook/";
        allowJsTransformationFunctions = false;
        waitForComplete = false;
        userIdPrefix = "_webhooks_";
      };

      bot = {
        displayname = "Hookshot";
      };
    };

    serviceDependencies = [ "tuwunel.service" ];
  };

  services.matrix-tuwunel.settings.global.appservice_dir = "/var/lib/matrix-hookshot/appservices";

  systemd.services.tuwunel = {
    after = [ "matrix-hookshot-registration.service" ];
    wants = [ "matrix-hookshot-registration.service" ];
  };

  systemd.tmpfiles.rules = [
    "d /var/lib/matrix-hookshot 0750 matrix-hookshot tuwunel - -"
    "d /var/lib/matrix-hookshot/appservices 0750 matrix-hookshot tuwunel - -"
  ];

  users.users.matrix-hookshot = {
    isSystemUser = true;
    group = "matrix-hookshot";
    extraGroups = [ "tuwunel" ];
  };
  users.groups.matrix-hookshot = { };

  systemd.services.matrix-hookshot-registration = {
    description = "Matrix Hookshot registration bootstrap";
    before = [ "matrix-hookshot.service" ];
    requiredBy = [ "matrix-hookshot.service" ];
    path = [ pkgs.openssl ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
      User = "matrix-hookshot";
      Group = "matrix-hookshot";
    };
    script = ''
      if [ ! -f ${registrationFile} ]; then
        AS_TOKEN="$(openssl rand -hex 32)"
        HS_TOKEN="$(openssl rand -hex 32)"
        cat > ${registrationFile} << 'YAMLEOF'
      id: matrix-hookshot
      as_token: AS_TOKEN_PLACEHOLDER
      hs_token: HS_TOKEN_PLACEHOLDER
      namespaces:
        rooms: []
        users:
          - regex: "@_webhooks_.*:${domain}"
            exclusive: true
          - regex: "@hookshot_.*:${domain}"
            exclusive: true
      sender_localpart: hookshot
      url: "http://localhost:9993"
      rate_limited: false
      YAMLEOF
        ${pkgs.gnused}/bin/sed -i \
          "s/AS_TOKEN_PLACEHOLDER/$AS_TOKEN/" \
          ${registrationFile}
        ${pkgs.gnused}/bin/sed -i \
          "s/HS_TOKEN_PLACEHOLDER/$HS_TOKEN/" \
          ${registrationFile}
        chgrp tuwunel ${registrationFile}
        chmod 640 ${registrationFile}
      fi

      if [ ! -L /var/lib/matrix-hookshot/appservices/hookshot.yml ]; then
        ln -s ${registrationFile} /var/lib/matrix-hookshot/appservices/hookshot.yml
      fi
    '';
  };

  systemd.services.matrix-hookshot = {
    # Runs after the module's keygen preStart; keeps the passkey unreadable
    # by the tuwunel group now that the state dir is group-traversable.
    preStart = lib.mkAfter ''
      chmod 600 /var/lib/matrix-hookshot/passkey.pem
    '';
    serviceConfig = {
      User = "matrix-hookshot";
      Group = "matrix-hookshot";
      # No StateDirectory: systemd would chown the tree back to
      # matrix-hookshot:matrix-hookshot and lock tuwunel out of the
      # appservice registration. ReadWritePaths keeps it writable instead.
      ReadWritePaths = [ "/var/lib/matrix-hookshot" ];
      RuntimeDirectory = "matrix-hookshot";
      RuntimeDirectoryMode = "0700";
      ProtectSystem = "strict";
      ProtectHome = true;
      PrivateTmp = true;
      NoNewPrivileges = true;
    };
  };

  services.caddy.virtualHosts."hooks.${domain}" = {
    extraConfig = ''
      reverse_proxy localhost:9000
    '';
  };
}
