#!/usr/bin/env bash
set -uo pipefail

# One safe Nextcloud major-version step.
#
# A Nextcloud major upgrade rewrites the database and is NOT undone by rolling
# back the NixOS generation, and Nextcloud refuses to cross more than one major
# at a time. So this script enforces the two things that actually matter:
#
#   1. the configured package is exactly ONE major above what is installed
#   2. a verified files+database backup exists, taken just now
#
# and only then rebuilds. If the backup does not verify, it does not rebuild.
#
# Run as root. Usage:
#   nextcloud-upgrade-step.sh            # check, back up, rebuild
#   nextcloud-upgrade-step.sh --check    # check only, change nothing

FLAKE=/home/freerat/config_flake
HOST=maliketh
BACKUP_SCRIPT="$FLAKE/scripts/nextcloud-backup-now.sh"
OCC=nextcloud-occ

say()  { printf '\n\033[0;36m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[0;32m    PASS\033[0m %s\n' "$*"; }
bad()  { printf '\033[0;31m    FAIL\033[0m %s\n' "$*"; }
note() { printf '         %s\n' "$*"; }
die()  { printf '\n\033[0;31m==> FATAL:\033[0m %s\n' "$*" >&2; exit 2; }

CHECK_ONLY=false
[ "${1:-}" = "--check" ] && CHECK_ONLY=true

[ "$(id -u)" -eq 0 ] || die "run as root"
command -v "$OCC" >/dev/null || die "$OCC not on PATH"

say "Installed vs configured"
# occ status reports the running instance's version, which is what the next
# upgrade is allowed to step from.
INSTALLED=$("$OCC" status --output=json 2>/dev/null \
    | tr ',' '\n' | sed -n 's/.*"versionstring":"\([^"]*\)".*/\1/p' | head -1)
[ -n "$INSTALLED" ] || INSTALLED=$("$OCC" status 2>/dev/null | sed -n 's/.*versionstring: *//p' | head -1)
[ -n "$INSTALLED" ] || die "could not read the installed version from '$OCC status'"

CONFIGURED=$(nix eval --raw "$FLAKE#nixosConfigurations.$HOST.config.services.nextcloud.package.version" 2>/dev/null)
[ -n "$CONFIGURED" ] || die "could not read the configured package version from the flake"

IMAJ=${INSTALLED%%.*}
CMAJ=${CONFIGURED%%.*}
note "installed:  $INSTALLED  (major $IMAJ)"
note "configured: $CONFIGURED  (major $CMAJ)"

if [ "$CMAJ" = "$IMAJ" ]; then
    ok "already on major $IMAJ — nothing to upgrade"
    note "to step up, set services.nextcloud.package = pkgs.nextcloud$((IMAJ + 1)) in infra/nextcloud.nix"
    exit 0
fi
if [ "$CMAJ" -lt "$IMAJ" ]; then
    die "configured major ($CMAJ) is OLDER than installed ($IMAJ). Nextcloud cannot downgrade; fix infra/nextcloud.nix."
fi
if [ "$((CMAJ - IMAJ))" -ne 1 ]; then
    die "configured major ($CMAJ) is $((CMAJ - IMAJ)) ahead of installed ($IMAJ). Nextcloud only supports one major at a time — set pkgs.nextcloud$((IMAJ + 1)) first."
fi
ok "exactly one major step: $IMAJ -> $CMAJ"

say "Pre-upgrade state"
"$OCC" status 2>&1 | sed 's/^/         /'
note "apps that are already disabled (for comparison afterwards):"
"$OCC" app:list --output=json 2>/dev/null \
    | tr ',' '\n' | sed -n '/disabled/,$p' | head -20 | sed 's/^/           /' || true

if [ "$CHECK_ONLY" = true ]; then
    say "--check given: stopping here, nothing changed"
    exit 0
fi

say "Taking a fresh verified backup before touching anything"
[ -x "$BACKUP_SCRIPT" ] || die "$BACKUP_SCRIPT not found"
if ! "$BACKUP_SCRIPT"; then
    die "backup did not verify — REFUSING to upgrade. Fix the backup first; the migration is irreversible."
fi
ok "backup verified"

say "Rebuilding to Nextcloud $CMAJ"
if ! nixos-rebuild switch --flake "$FLAKE#$HOST"; then
    die "nixos-rebuild failed. Nextcloud may be mid-upgrade — check 'systemctl status nextcloud-update-db' and the journal."
fi

say "Post-upgrade state"
sleep 2
if systemctl is-active phpfpm-nextcloud >/dev/null 2>&1; then
    ok "phpfpm-nextcloud active"
else
    bad "phpfpm-nextcloud not active"
fi
UPD=$(systemctl show nextcloud-update-db -p Result --value 2>/dev/null)
if [ "$UPD" = success ]; then
    ok "nextcloud-update-db: success"
else
    bad "nextcloud-update-db: ${UPD:-unknown}"
fi

NOW=$("$OCC" status 2>/dev/null | sed -n 's/.*versionstring: *//p' | head -1)
note "version now: ${NOW:-unreadable}"
if [ "${NOW%%.*}" = "$CMAJ" ]; then
    ok "running major $CMAJ"
else
    bad "expected major $CMAJ but see ${NOW:-nothing} — check the journal"
fi

"$OCC" status 2>&1 | sed 's/^/         /'
note "maintenance mode should be false above; if it is true:"
note "  nextcloud-occ maintenance:mode --off"

say "Things worth checking by hand"
note "- apps disabled by the upgrade:  nextcloud-occ app:list"
note "- missing DB indices/columns:    nextcloud-occ db:add-missing-indices"
note "                                 nextcloud-occ db:add-missing-columns"
note "- overall:                       nextcloud-occ status && nextcloud-occ check"
note "- then the next step, if wanted: set pkgs.nextcloud$((CMAJ + 1)) and re-run this"
