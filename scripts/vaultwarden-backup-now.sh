#!/usr/bin/env bash
set -uo pipefail

# One-shot verified Vaultwarden backup.
#
# Mirrors what the NixOS module's own backup does (nixos/modules/services/
# security/vaultwarden/backup.sh), which in turn follows the upstream wiki:
#   https://github.com/dani-garcia/vaultwarden/wiki/Backing-up-your-vault
#
#   sqlite3 db.sqlite3 ".backup '<dest>/db.sqlite3'"   then copy everything but db.*
#
# Two things this gets right that a naive copy does not:
#
#  * The database is captured with SQLite's ONLINE BACKUP API, not copied. A
#    plain copy of a live WAL-mode database can be torn, and copying db.sqlite3
#    without its -wal leaves committed transactions behind.
#  * It runs as the vaultwarden user, NOT root. Opening a live WAL database
#    creates/updates -shm and -wal beside it; doing that as root would leave
#    root-owned files in a 0700 vaultwarden directory and break the service.
#
# No maintenance window is needed — Vaultwarden stays up throughout.
#
# Invoke as root (it drops to vaultwarden for the parts that touch the data).

DATA=/var/lib/vaultwarden
STAGE=/var/backup/vaultwarden   # outside $DATA, and outside $DEST_ROOT so it
                                # cannot collide with its own snapshot-set dir
DEST_ROOT=/home/freerat/backups
BACKUP=/home/freerat/config_flake/scripts/backup.sh
VW_USER=vaultwarden
VW_GROUP=vaultwarden

say()  { printf '\n\033[0;36m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[0;32m    PASS\033[0m %s\n' "$*"; }
bad()  { printf '\033[0;31m    FAIL\033[0m %s\n' "$*"; }
note() { printf '         %s\n' "$*"; }
warn() { printf '\033[1;33m==> WARNING:\033[0m %s\n' "$*" >&2; }
die()  { printf '\n\033[0;31m==> FATAL:\033[0m %s\n' "$*" >&2; exit 2; }

[ "$(id -u)" -eq 0 ] || die "run as root ($DATA is 0700 $VW_USER)"
[ -d "$DATA" ] || die "$DATA does not exist"
[ -x "$BACKUP" ] || die "$BACKUP not found"
id "$VW_USER" >/dev/null 2>&1 || die "no such user: $VW_USER"

# sqlite3 is not in this system's PATH, so find it without needing a rebuild.
SQLITE="${SQLITE:-$(command -v sqlite3 2>/dev/null)}"
if [ -z "$SQLITE" ]; then
    SQLITE=$(find /nix/store -maxdepth 3 -type f -path '*-sqlite-*-bin/bin/sqlite3' 2>/dev/null | head -1)
fi
if [ -z "$SQLITE" ]; then
    SQLITE="$(nix build --no-link --print-out-paths nixpkgs#sqlite 2>/dev/null | head -1)/bin/sqlite3"
fi
[ -x "$SQLITE" ] || die "could not find sqlite3; set SQLITE=/path/to/sqlite3"
note "sqlite3: $SQLITE"

# Same story for openssl — used to prove the RSA key parses, not just exists.
OPENSSL="${OPENSSL:-$(command -v openssl 2>/dev/null)}"
if [ -z "$OPENSSL" ]; then
    OPENSSL=$(find /nix/store -maxdepth 3 -type f -path '*-openssl-*-bin/bin/openssl' 2>/dev/null | head -1)
fi
[ -n "$OPENSSL" ] && [ -x "$OPENSSL" ] || OPENSSL=""
note "openssl: ${OPENSSL:-not found (key validation will be skipped)}"

# 0770 vaultwarden:vaultwarden — same as the module's tmpfiles rule, so the
# vaultwarden user can write the backup here.
install -d -m 0770 -o "$VW_USER" -g "$VW_GROUP" "$STAGE" || die "cannot create $STAGE"
mkdir -p "$DEST_ROOT"

say "Source"
du -sh "$DATA" 2>/dev/null | sed 's/^/         data:   /'
df -h "$DEST_ROOT" | tail -1 | awk '{print "         target: " $4 " free on " $6}'

RC=0

# --- database, via the online backup API ------------------------------------
# Done FIRST, deliberately. The database is the authoritative index of
# attachments; if a new attachment lands between the two steps it ends up on
# disk without a database row (a harmless orphan). The other order would give a
# row pointing at a file that was never copied.
say "Backing up the database with SQLite's online backup API (service stays up)"
if [ ! -f "$DATA/db.sqlite3" ]; then
    die "$DATA/db.sqlite3 not found — is this really a sqlite-backed instance?"
fi
if runuser -u "$VW_USER" -- "$SQLITE" "$DATA/db.sqlite3" ".backup '$STAGE/db.sqlite3'"; then
    chmod 0600 "$STAGE/db.sqlite3"
    note "wrote $STAGE/db.sqlite3 ($(du -h "$STAGE/db.sqlite3" | cut -f1))"
else
    die "sqlite3 .backup failed"
fi

# --- everything else --------------------------------------------------------
say "Copying the rest of the data folder (keys, attachments, sends, config)"
# Excludes db.* so the live database files are never copied byte-wise: the
# consistent copy above is the one to restore from. Copying db.sqlite3 alone is
# not merely stale but can be unusable — with an open connection and an
# uncheckpointed WAL, the schema itself lives in the -wal file.
#
# The exclude list is exactly the module's `cp -r "$DATA_FOLDER"/!(db.*)`, and
# deliberately no wider: both write into this same staging directory, and
# --delete here would otherwise keep removing whatever the module's timer just
# copied.
if runuser -u "$VW_USER" -- rsync -a --delete \
        --exclude 'db.sqlite3' --exclude 'db.sqlite3-wal' --exclude 'db.sqlite3-shm' \
        "$DATA/" "$STAGE/"; then
    note "copied"
else
    die "copying the data folder failed"
fi

say "What the staged backup contains"
find "$STAGE" -maxdepth 1 -mindepth 1 -printf '         %-28f %s bytes\n' 2>/dev/null | sort

# The RSA keypair signs session tokens: without it every client is logged out.
# A filename check is not enough — a truncated or corrupt key passes that and
# still breaks every session on restore. So parse it, and fingerprint it against
# the live key to prove it is the RIGHT key and not merely a valid one.
say "Checking the RSA key material actually parses"
mapfile -t KEYFILES < <(find "$STAGE" -maxdepth 1 -type f \
    \( -name '*rsa_key*' -o -name '*.pem' -o -name '*.der' \) 2>/dev/null | sort)
if [ "${#KEYFILES[@]}" -eq 0 ]; then
    bad "no RSA key files in the backup — after a restore every client must log in again"
    RC=1
elif [ -z "$OPENSSL" ]; then
    warn "openssl not found; could not validate the key files (found ${#KEYFILES[@]})"
else
    KEY_OK=0
    for kf in "${KEYFILES[@]}"; do
        desc="" fp=""
        if "$OPENSSL" pkey -in "$kf" -noout 2>/dev/null; then
            desc="private key, $("$OPENSSL" pkey -in "$kf" -noout -text 2>/dev/null | grep -oE '\(?[0-9]+ bit' | head -1 | tr -d '(') "
            fp=$("$OPENSSL" pkey -in "$kf" -pubout -outform DER 2>/dev/null | sha256sum | cut -c1-16)
        elif "$OPENSSL" pkey -inform DER -in "$kf" -noout 2>/dev/null; then
            desc="private key (DER) "
            fp=$("$OPENSSL" pkey -inform DER -in "$kf" -pubout -outform DER 2>/dev/null | sha256sum | cut -c1-16)
        elif "$OPENSSL" pkey -pubin -in "$kf" -noout 2>/dev/null \
          || "$OPENSSL" pkey -pubin -inform DER -in "$kf" -noout 2>/dev/null; then
            desc="public key "
        fi
        if [ -n "$desc" ]; then
            note "$(basename "$kf"): $desc${fp:+pubkey sha256 $fp...}"
            case "$desc" in private*) KEY_OK=1 ;; esac
            # Same key as the live instance is using?
            live="$DATA/$(basename "$kf")"
            if [ -n "$fp" ] && [ -f "$live" ]; then
                lfp=$("$OPENSSL" pkey -in "$live" -pubout -outform DER 2>/dev/null | sha256sum | cut -c1-16)
                [ -z "$lfp" ] && lfp=$("$OPENSSL" pkey -inform DER -in "$live" -pubout -outform DER 2>/dev/null | sha256sum | cut -c1-16)
                if [ "$fp" = "$lfp" ]; then
                    ok "$(basename "$kf") is the same key the live instance is using"
                else
                    bad "$(basename "$kf") does NOT match the live key ($fp vs ${lfp:-unreadable})"
                    RC=1
                fi
            fi
        else
            bad "$(basename "$kf") does not parse as a key — would not survive a restore"
            RC=1
        fi
    done
    if [ "$KEY_OK" -eq 1 ]; then
        ok "a usable private key is in the backup — sessions survive a restore"
    else
        bad "no parseable PRIVATE key in the backup — every client would be logged out"
        RC=1
    fi
fi

# --- verify the database copy ----------------------------------------------
say "Verifying the database copy"
INTEG=$(runuser -u "$VW_USER" -- "$SQLITE" "$STAGE/db.sqlite3" 'PRAGMA integrity_check;' 2>&1)
if [ "$INTEG" = "ok" ]; then
    ok "PRAGMA integrity_check: ok"
else
    bad "PRAGMA integrity_check: $INTEG"
    RC=1
fi

# Row counts against the live database. -readonly guarantees we cannot write to
# the live file while reading it.
say "Row counts, backup vs live"
printf '         %-18s %10s %10s\n' TABLE BACKUP LIVE
for t in users ciphers folders organizations attachments sends devices; do
    B=$(runuser -u "$VW_USER" -- "$SQLITE" -readonly "$STAGE/db.sqlite3" \
            "select count(*) from $t;" 2>/dev/null)
    L=$(runuser -u "$VW_USER" -- "$SQLITE" -readonly "$DATA/db.sqlite3" \
            "select count(*) from $t;" 2>/dev/null)
    mark=""
    if [ -n "$B" ] && [ -n "$L" ] && [ "$B" != "$L" ]; then mark="  <- differs (live activity since the copy)"; fi
    printf '         %-18s %10s %10s%s\n' "$t" "${B:-n/a}" "${L:-n/a}" "$mark"
done

# --- snapshot it -----------------------------------------------------------
say "Snapshotting the staged backup into $DEST_ROOT"
if ! "$BACKUP" create "$STAGE" --dest-root "$DEST_ROOT" --checksum; then
    bad "snapshot failed"
    RC=1
else
    say "Verifying the snapshot"
    if "$BACKUP" verify "$STAGE" --dest-root "$DEST_ROOT"; then
        ok "snapshot matches the staged backup"
    else
        bad "snapshot verify failed"
        RC=1
    fi
fi

# A vault backup is as sensitive as the vault. Keep the set directory
# non-traversable by other users; the files inside are already 0600/0700.
chmod 0700 "$DEST_ROOT/$(basename "$STAGE")" 2>/dev/null || true

say "Result"
"$BACKUP" list "$STAGE" --dest-root "$DEST_ROOT" || true

printf '\n'
if [ "$RC" -eq 0 ]; then
    printf '\033[0;32m==> VAULTWARDEN BACKUP VERIFIED\033[0m\n'
    printf '    %s/vaultwarden/\n' "$DEST_ROOT"
    printf '\n    To restore: stop vaultwarden, replace %s with the\n' "$DATA"
    printf '    snapshot contents (keeping ownership %s:%s), start it again.\n' "$VW_USER" "$VW_GROUP"
    printf '    The RSA key must be restored too, or every client is logged out.\n'
    exit 0
fi
printf '\033[0;31m==> NOT A VERIFIED BACKUP\033[0m — see the failures above\n'
exit 1
