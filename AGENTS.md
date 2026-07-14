# AGENTS.md

## What this is

A NixOS/Nix-Darwin flake managing multiple machines with home-manager. All machine names are Elden Ring / Dark Souls references.

## Hosts

| Name | Role | Platform | Rebuild command |
|------|------|----------|-----------------|
| ranni | Laptop | x86_64-linux (NixOS) | `sudo nixos-rebuild switch --flake .#ranni` |
| malenia | Desktop | x86_64-linux (NixOS) | `sudo nixos-rebuild switch --flake .#malenia` |
| maliketh | Mini PC server | x86_64-linux (NixOS) | `sudo nixos-rebuild switch --flake .#maliketh` |
| melina | Raspberry Pi | NixOS (no hyprland) | `sudo nixos-rebuild switch --flake .#melina` |
| hyetta | Macbook (different user: tomaszlawicki) | aarch64-darwin | `darwin-rebuild switch --flake .#Tomaszs-MacBook-Air` |

## Structure

- `flake.nix` — all host definitions, inputs, and wiring
- `hosts/<name>/` — per-host hardware/config (ranni, malenia, maliketh, melina use `configuration.nix` + `hardware-configuration.nix`; hyetta uses `default.nix`)
- `modules/` — shared NixOS modules; `default.nix` is the common base, `hyprland/` is the active WM, others (awesome, xmonad, sway, river, niri, qtile) are commented out
- `modules/darwin.nix` — macOS-specific module
- `home/` — home-manager configs; `home.nix` for GUI hosts, `melina.nix` for headless, `darwin.nix` for macOS
- `home/programs/` — per-program home-manager modules (nvf, kitty, alacritty, wezterm, rofi, nushell, etc.)
- `infra/` — infrastructure modules (`maliketh_services.nix` caddy + personal website, individual service modules)
- `scripts/` — utility shell scripts (wallpaper change, color update, nix cleanup)
- `colors/` — generated color palettes
- `wallpapers/` — image files used by wallust theming

## Key conventions

- Config path hardcoded as `/home/freerat/config_flake` in `modules/default.nix` env vars — changing it requires updating that file
- Active window manager: **hyprland** (others are commented out in `flake.nix` outputs)
- `scripts/clean_nix.sh` uses `sudo nixos-rebuild switch --flake /home/freerat/config_flake` (no hostname qualifier — targets current system)
- Wallpaper workflow: `scripts/changeWallpaper.sh` (fzf picker + wallust), `scripts/updateColors.sh` reads `~/.wallpaper_path`
- `.gitignore` excludes generated files: `home/wallpapers/.colors.scss`, `home/wallpapers/.wallpaper`, waybar colors
- `infra/maliketh_services.nix` enables Caddy reverse proxy + personal website on `free-rat.dev`; the `package` option is explicitly set to the personal-website input package (avoids `self` ambiguity)
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
| Homepage | home.free-rat.dev | 8082 | `infra/homepage-dashboard.nix` |
| Caddy proxy | — | 80/443 | `infra/maliketh_services.nix` |

### Setup notes

- **Vaultwarden admin token**: Auto-generated at `/var/lib/vaultwarden/admin-token`. Access admin at `https://vault.free-rat.dev/admin`.
- **Nextcloud admin password**: Auto-generated at `/var/lib/nextcloud/admin-pass`.
- No PostgreSQL for Nextcloud only — Forgejo, Vaultwarden, and n8n use SQLite.
- Nextcloud uses PostgreSQL (`services.postgresql` enabled by the nextcloud module).