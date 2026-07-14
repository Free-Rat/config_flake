{ config, lib, pkgs, ... }:
{
  services.homepage-dashboard = {
    enable = true;
    listenPort = 8082;

    settings = {
      title = "free-rat";
      description = "Services on maliketh";
      theme = "dark";
      color = "slate";
      headerStyle = "boxed";
    };

    services = [
      {
        "Services" = [
          {
            "Forgejo" = {
              href = "https://git.free-rat.dev";
              description = "Self-hosted Git";
              icon = "gitea.png";
              siteMonitor = "http://localhost:3000";
            };
          }
          {
            "Vaultwarden" = {
              href = "https://vault.free-rat.dev";
              description = "Password manager";
              icon = "vaultwarden.png";
              siteMonitor = "http://localhost:8222";
            };
          }
          {
            "n8n" = {
              href = "https://n8n.free-rat.dev";
              description = "Workflow automation";
              icon = "n8n.svg";
              siteMonitor = "http://localhost:5678";
            };
          }
          {
            "Nextcloud" = {
              href = "https://cloud.free-rat.dev";
              description = "File sync & sharing";
              icon = "nextcloud.png";
              siteMonitor = "http://localhost:8091";
            };
          }
        ];
      }
    ];

    widgets = [
      {
        resources = {
          cpu = true;
          memory = true;
          disk = "/";
        };
      }
      {
        search = {
          provider = "duckduckgo";
          target = "_blank";
        };
      }
    ];

    bookmarks = [
      {
        "nix" = [
          { "NixOS search" = [{ abbr = "NX"; href = "https://search.nixos.org/packages"; }]; }
          { "Home Manager" = [{ abbr = "HM"; href = "https://nix-community.github.io/home-manager/options.xhtml"; }]; }
        ];
      }
    ];
  };

  services.caddy.virtualHosts."home.free-rat.dev".extraConfig = ''
    reverse_proxy localhost:8082
  '';
}
