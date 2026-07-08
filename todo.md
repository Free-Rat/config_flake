# TODO

## Cloudflare proxy + DNS-01 for Caddy on maliketh

Currently `free-rat.dev` uses a grey-cloud A record. Switch to orange cloud (Cloudflare proxy) and configure Caddy to use DNS-01 ACME challenge via the `caddy-dns-cloudflare` plugin.

### Steps

1. Add `caddy-dns-cloudflare` plugin to the Caddy build in the NixOS config
   - In `infra/maliketh_services.nix`, use `services.caddy.package = pkgs.caddy.withPlugins { plugins = [...]; }` or override with `xdg.caddy.plugins`
   - Plugin: `github.com/caddy-dns/cloudflare`

2. Create a Cloudflare API token (scoped to DNS edit for `free-rat.dev` zone only)

3. Add the token as a NixOS secret (e.g. `/var/lib/caddy/cloudflare-api-token` or via `sops-nix`)

4. Update `infra/maliketh_services.nix` Caddy config to use DNS-01:
   ```nix
   services.caddy.virtualHosts."free-rat.dev".extraConfig = ''
     root * ${inputs.personal-website.packages.${pkgs.stdenv.hostPlatform.system}.website}
     file_server

     tls {
       dns cloudflare {env.CLOUDFLARE_API_TOKEN}
     }
   '';
   ```

5. Set the env var via systemd override or `environmentFile`:
   ```nix
   systemd.services.caddy.environment.CLOUDFLARE_API_TOKEN = "/var/lib/caddy/cloudflare-api-token";
   ```
   Or pass it inline (less secure, for testing).

6. Switch the Cloudflare DNS record from grey cloud (DNS only) to orange cloud (proxied)

7. Test: `curl -v https://free-rat.dev` should serve the site through Cloudflare with a valid cert

### Reference
- https://github.com/caddy-dns/cloudflare
- https://caddyserver.com/docs/command-line#caddy-with-plugins