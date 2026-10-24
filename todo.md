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
## Finish setting up matrix-hookshot

`infra/hookshot.nix` is written and the module is exported as
`self.nixosModules.hookshot`, but it is **commented out of maliketh's module
list in flake.nix**. Enabling it as-is only produces a failing unit, because the
bridge has never been registered with tuwunel or invited to a room.

Context: it was enabled on 2026-10-24 and `matrix-hookshot.service` failed with
`EACCES` on `/var/lib/matrix-hookshot/registration.yml`. That specific bug is
already fixed in the module (see below), but the setup work was never done, so
it was disabled again rather than left broken.

### Already fixed, don't re-debug

- The bootstrap (`matrix-hookshot-registration.service`) now runs as **root** and
  unconditionally does `chown -R tuwunel:tuwunel /var/lib/matrix-hookshot` plus
  `chmod 600` on `registration.yml` and `passkey.pem`.
  Why it was needed: the module used to run as its own `matrix-hookshot` user.
  When that user was removed in favour of reusing `tuwunel`, the existing state
  files were left `0600` owned by an orphaned numeric uid (987:985), which
  tuwunel can neither read nor chown. The old script only chmod'd inside
  `if [ ! -f ]`, so no rebuild could ever repair it.
- Hookshot runs as `tuwunel:tuwunel` (`config.services.matrix-tuwunel.user`),
  so no second service user is created.

### Leftover state on disk

`/var/lib/matrix-hookshot/` still exists with `registration.yml`, `passkey.pem`
and `appservices/hookshot.yml`, some owned by uid 987:985. Either let the fixed
bootstrap adopt them on re-enable, or delete the directory for a clean start —
deleting means new `as_token`/`hs_token`, so tuwunel's registration must be
redone to match.

### Steps to actually finish it

1. Uncomment `self.nixosModules.hookshot` in `flake.nix` (maliketh's
   `nixosModules` list) and rebuild.
2. Check `systemctl status matrix-hookshot` and
   `journalctl -u matrix-hookshot`. If it had previously hit its restart limit,
   `systemctl reset-failed matrix-hookshot` first — the `start-limit-hit` latch
   survives a switch.
3. Make tuwunel load the appservice registration. Hookshot writes it to
   `/var/lib/matrix-hookshot/registration.yml` and symlinks it into
   `appservices/`, but `infra/tuwunel.nix` does not reference that path at all,
   so tuwunel currently never reads it. This is the main missing piece.
4. Invite `@hookshot:free-rat.dev` to a room, give it Moderator power level,
   then `!hookshot help` to confirm the bridge is responding.
5. For the n8n use case, outbound webhooks are already enabled
   (`generic.outbound = true`) and `permissions` grants `admin` to the domain.
   Configure the connection through the Element widget (room settings →
   Widgets) or the provisioning API on `127.0.0.1:9001/v1`.
6. `hooks.free-rat.dev` is proxied by Caddy from within `infra/hookshot.nix`,
   so that vhost disappears while the module is disabled.

### Reference

- https://matrix-org.github.io/matrix-hookshot/latest/setup.html
- Element widget / provisioning API: listener on port 9001 (`metrics`,
  `provisioning`), bound to 127.0.0.1
