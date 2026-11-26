# AGENTS.md

## What this is

A NixOS/Nix-Darwin flake managing multiple machines with home-manager. All machine names are Elden Ring / Dark Souls references.

## Hosts

| Name | Role | Platform | Rebuild command |
|------|------|----------|-----------------|
| ranni | Laptop | x86_64-linux (NixOS) | `sudo nixos-rebuild switch --flake .#ranni` |
| rennala | Laptop | x86_64-linux (NixOS) | `sudo nixos-rebuild switch --flake .#rennala` |
| malenia | Desktop | x86_64-linux (NixOS) | `sudo nixos-rebuild switch --flake .#malenia` |
| maliketh | Mini PC server | x86_64-linux (NixOS) | `sudo nixos-rebuild switch --flake .#maliketh` |
| melina | Raspberry Pi | NixOS (no hyprland) | `sudo nixos-rebuild switch --flake .#melina` |
| hyetta | Macbook (different user: tomaszlawicki) | aarch64-darwin | `darwin-rebuild switch --flake .#Tomaszs-MacBook-Air` |

## Structure

- `flake.nix` — all host definitions, inputs, and wiring
- `hosts/<name>/` — per-host hardware/config (ranni, rennala, malenia, maliketh, melina use `configuration.nix` + `hardware-configuration.nix`; hyetta uses `default.nix`)
- `modules/` — shared NixOS modules; `default.nix` is the common base, `hyprland/` is the active WM, others (awesome, xmonad, sway, river, niri, qtile) are commented out
- `modules/darwin.nix` — macOS-specific module
- `home/` — home-manager configs; `home.nix` for GUI hosts, `melina.nix` for headless, `darwin.nix` for macOS
- `home/programs/` — per-program home-manager modules (nvf, kitty, alacritty, wezterm, rofi, nushell, etc.)
- `infra/` — infrastructure modules (`caddy.nix` Caddy reverse proxy, `personal_website.nix` personal website, individual service modules)
- `scripts/` — utility shell scripts (wallpaper change, color update, nix cleanup, local backups)
- `colors/` — generated color palettes
- `wallpapers/` — images now live in `/home/freerat/Nextcloud/wallpapers` (outside the repo), used by wallust theming

## Key conventions

- Config path hardcoded as `/home/freerat/config_flake` in `modules/default.nix` env vars — changing it requires updating that file
- Active window manager: **hyprland** (others are commented out in `flake.nix` outputs)
- `scripts/clean_nix.sh` uses `nixos-rebuild switch --sudo --flake /home/freerat/config_flake` (no hostname qualifier — targets current system). `--sudo` instead of a leading `sudo`: evaluation must run as the user, because the `personal-website` input is fetched over SSH and root has no Forgejo key
- Wallpaper workflow: `scripts/changeWallpaper.sh` (fzf picker + wallust), `scripts/updateColors.sh` reads `$PATH_WALLPAPERS/.wallpaper`
- `scripts/backup.sh` — incremental local backups of a given directory via rsync hardlink snapshots into `/var/backup/<name>/` (override with `--dest-root` or `$BACKUP_DEST_ROOT`). Needs root to preserve ownership/ACLs/xattrs. No scheduling is wired up; run it by hand or add a timer. Subcommands: `create`, `verify`, `list`, `restore`, `prune`. Exit codes: 0 ok, 2 usage error or refused operation, 3 verify failed — so `create --checksum && verify && <next step>` is a real gate. `verify` catches accident, corruption and interrupted runs, not an adversary with write access to the dest-root (nothing is signed) — set permissions on `/var/backup` accordingly. Default comparison is size+mtime, which misses a change that preserves both; pass `--checksum` for a backup you intend to rely on. Snapshots share inodes, so never write inside a snapshot directory — use `restore`, which copies and refuses a target inside the dest-root. `restore` merges by default and deletes nothing; `--mirror` deletes extra files at the target and refuses a system root, a non-empty target, or a `PARTIAL`/`-x` snapshot unless `--force`. Databases are out of scope: dump Postgres separately, outside the Nextcloud data root, with the service stopped (see the script's `--help`)
- Workspace overview (niri-style, SUPER+TAB): quickshell config in `programs/quickshell/overview/shell.qml`, run by the `quickshell-overview` systemd user service (restarts on crash; `systemctl --user restart quickshell-overview`); `~/.config/quickshell/overview` is an out-of-store symlink to the repo folder, so saving `shell.qml` hot-reloads the running overview without a rebuild. Hyprland's config is Lua (`modules/hyprland/hyprland.lua`, ≥ 0.57), which only accepts Lua dispatches (`hyprctl dispatch 'hl.dsp.focus({ workspace = 2 })'`); quickshell 0.3.2's `Hyprland.dispatch()` doesn't reach it, so the overview shells out to `hyprctl`. SUPER+J/K (`ws_stack` in `hyprland.lua`) and the overview rows (`entries` in `shell.qml`) share one workspace order — named alphabetically, then numbered, gaps skipped — so change both together.
- `.gitignore` excludes generated waybar colors; wallust-generated files (`.colors.scss`, `.wallpaper`) live in the Nextcloud wallpapers dir outside the repo
- `infra/caddy.nix` enables Caddy reverse proxy with domain redirects (e.g. `tomasz.bijeswoja.zone` → `free-rat.dev`)
- `infra/personal_website.nix` serves personal website on `free-rat.dev`; the `package` option is explicitly set to the personal-website input package (avoids `self` ambiguity)
- Maliketh has a static IP (192.168.1.107) — if the interface name changes, update `hosts/maliketh/configuration.nix`

## Flake commands

```sh
# Rebuild current NixOS host (pick hostname)
sudo nixos-rebuild switch --flake .#ranni
sudo nixos-rebuild switch --flake .#malenia

# Rebuild macOS host
darwin-rebuild switch --flake .#Tomaszs-MacBook-Air

# Update a single input
nix flake lock --update-input nvf

# Full update of all inputs
nix flake update
```

## Inputs

- `nixpkgs` — nixos-unstable
- `home-manager` — follows nixpkgs
- `nix-darwin` — follows nixpkgs
- `nvf` — neovim config (github:Free-Rat/nvf), follows nixpkgs
- `eirian-font` — custom font (github:Free-Rat/eirian-font-nix-pkgs)
- `personal-website` — personal website (github:Free-Rat/personal-website), follows nixpkgs

## Services (maliketh)

Each service uses its own built-in authentication.

| Service | Domain | Port | Module |
|---------|--------|------|--------|
| Forgejo | git.free-rat.dev | 3000 | `infra/forgejo.nix` |
| Vaultwarden | vault.free-rat.dev | 8222 | `infra/vaultwarden.nix` |
| n8n | n8n.free-rat.dev | 5678 | `infra/n8n.nix` |
| Nextcloud | cloud.free-rat.dev | 8091 (nginx) | `infra/nextcloud.nix` |
| Homepage | dash.free-rat.dev | 8082 | `infra/homepage-dashboard.nix` |
| Tuwunel (Matrix) | — | — | `infra/tuwunel.nix` |
| Element | — | — | `infra/element.nix` |
| Hookshot | hooks.free-rat.dev | 9993, 9001 (metrics/provisioning) | `infra/hookshot.nix` — **disabled**, commented out of maliketh's module list in `flake.nix`; see `todo.md` |
| Caddy proxy | — | 80/443 | `infra/caddy.nix` |

### Setup notes

- **Vaultwarden admin token**: Auto-generated at `/var/lib/vaultwarden/admin-token`. Access admin at `https://vault.free-rat.dev/admin`.
- **Vaultwarden backups**: `services.vaultwarden.backupDir = "/var/backup/vaultwarden"` enables the module's `backup-vaultwarden` service and a 23:00 daily timer (`OnCalendar` is `mkDefault`). It uses `sqlite3 .backup` — the SQLite online backup API — because a byte copy of a live WAL database can be unusable: with an open connection and an uncheckpointed WAL, the schema itself lives in the `-wal` file. Run it on demand with `systemctl start backup-vaultwarden`. That only refreshes the staging copy; `scripts/vaultwarden-backup-now.sh` does the dump, snapshots it into `~/backups/vaultwarden/`, and verifies it (integrity check plus row counts against the live DB). The RSA keypair in the data dir signs session tokens — restore it or every client is logged out.
- **Nextcloud admin password**: at `/var/lib/nextcloud/admin-pass`, generated by the original install. Nextcloud 33 removed `services.nextcloud.config.adminuser`/`adminpassFile`, so nothing regenerates it now; further users are made with `nextcloud-occ user:add <name>` + `nextcloud-occ group:adduser admin <name>`.
- **Nextcloud upgrades**: `services.nextcloud.package` is pinned (currently `nextcloud33`) because Nextcloud refuses to skip a major version. Bump it one major at a time, and take a backup first (`scripts/backup.sh`) — the migration rewrites the database and is not undone by rolling back the NixOS generation.
- **Hookshot** runs as the `tuwunel` user/group rather than its own, so it can read the appservice registration it writes to `/var/lib/matrix-hookshot/registration.yml`.
- No PostgreSQL for Nextcloud only — Forgejo, Vaultwarden, and n8n use SQLite.
- Nextcloud uses PostgreSQL (`services.postgresql` enabled by the nextcloud module).
- **PostgreSQL collation mismatches after a nixpkgs bump**: when glibc changes, PostgreSQL warns `database "x" has a collation version mismatch`. This is not cosmetic — text indexes are stored in collation order, so an index built under the old rules can disagree with the new ones and queries can silently miss rows. Fix with `scripts/postgres-refresh-collation.sh` (`--check` to report only). It runs `REINDEX DATABASE` **then** `ALTER DATABASE … REFRESH COLLATION VERSION` — that order matters, because refreshing first just records "fine" over possibly-wrong indexes and loses the only signal that work is needed. It covers `template1` too, which new databases are cloned from. Last done 2026-10-24 (2.42 → 2.44).