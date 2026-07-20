{ config, lib, pkgs, ... }:
{
  services.matrix-tuwunel = {
    enable = true;

    settings.global = {
      server_name = "free-rat.dev";
      address = [ "127.0.0.1" "::1" ];
      port = [ 6167 ];
      allow_federation = true;
      allow_registration = true;
    };
  };

  services.caddy.virtualHosts."matrix.free-rat.dev".extraConfig = ''
    reverse_proxy localhost:6167
  '';

  services.caddy.virtualHosts."free-rat.dev".extraConfig = ''
    header /.well-known/matrix/* Content-Type application/json
    header /.well-known/matrix/* Access-Control-Allow-Origin *
    respond /.well-known/matrix/server `{"m.server": "matrix.free-rat.dev:443"}`
    respond /.well-known/matrix/client `{"m.homeserver": {"base_url": "https://matrix.free-rat.dev"}}`
  '';
}
