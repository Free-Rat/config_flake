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
- `infra/` — infrastructure modules (e.g. binary cache)
- `scripts/` — utility shell scripts (wallpaper change, color update, nix cleanup)
- `colors/` — generated color palettes
- `wallpapers/` — image files used by wallust theming

## Key conventions

- Config path hardcoded as `/home/freerat/config_flake` in `modules/default.nix` env vars — changing it requires updating that file
- Active window manager: **hyprland** (others are commented out in `flake.nix` outputs)
- `scripts/clean_nix.sh` uses `sudo nixos-rebuild switch --flake /home/freerat/config_flake` (no hostname qualifier — targets current system)
- Wallpaper workflow: `scripts/changeWallpaper.sh` (fzf picker + wallust), `scripts/updateColors.sh` reads `~/.wallpaper_path`
- `.gitignore` excludes generated files: `home/wallpapers/.colors.scss`, `home/wallpapers/.wallpaper`, waybar colors

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