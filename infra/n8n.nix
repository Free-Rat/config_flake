{ config, lib, pkgs, ... }:
{
  services.n8n = {
    enable = true;

    environment = {
      N8N_HOST = "localhost";
      N8N_PORT = "5678";
      N8N_PROTOCOL = "http";
      WEBHOOK_URL = "https://n8n.free-rat.dev";
      N8N_EDITOR_BASE_URL = "https://n8n.free-rat.dev";
      N8N_CODE_ENABLE_ALL_MODULES = "true";
      N8N_RUNNERS_AUTH_TOKEN_FILE = "/var/lib/n8n-task-runners/auth-token";
    };

    taskRunners = {
      enable = true;
    };
  };

  services.caddy.virtualHosts."n8n.free-rat.dev".extraConfig = ''
    reverse_proxy localhost:5678
  '';
}
