{ config, lib, pkgs, ... }:
let
  elementConfig = pkgs.writeText "config.json" (builtins.toJSON {
    default_server_config = {
      "m.homeserver" = {
        base_url = "https://matrix.free-rat.dev";
        server_name = "free-rat.dev";
      };
    };
    disable_custom_urls = true;
    disable_guests = true;
    disable_login_language_selector = false;
    disable_3pid_login = false;
    force_verification = false;
    brand = "Element";
    default_country_code = "PL";
    show_labs_settings = true;
    features = {
      feature_thread = true;
    };
    default_federate = true;
    default_theme = "dark";
    room_directory = {
      servers = [ "free-rat.dev" ];
    };
    setting_defaults = {
      breadcrumbs = true;
    };
  });

  element-web = pkgs.runCommand "element-web-configured" {} ''
    mkdir -p $out
    cp -r ${pkgs.element-web}/* $out/
    chmod u+w $out/config.json
    cp ${elementConfig} $out/config.json
  '';
in
{
  services.caddy.virtualHosts."chat.free-rat.dev" = {
    extraConfig = ''
      root * ${element-web}
      file_server
      encode zstd gzip
    '';
  };
}
