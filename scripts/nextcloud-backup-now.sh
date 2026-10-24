#!/usr/bin/env bash
set -uo pipefail

# One-shot verified Nextcloud backup — files AND database — following the
# upstream procedure:
# https://docs.nextcloud.com/server/stable/admin_manual/maintenance/backup.html
#
# Two passes, so the maintenance window is seconds rather than however long the
# bulk copy takes:
#   pass 1  service UP    — copies the bulk. May be internally inconsistent;
#                           it only exists to make pass 2 cheap.
#   pass 2  maintenance   — incremental on top of pass 1, so it writes almost
#                           nothing and is a consistent point-in-time snapshot.
#   dump    maintenance   — pg_dump in the SAME window, so files and database
#                           describe the same instant and restore as a pair.
#   verify  maintenance   — both snapshots confirmed against their sources.
#
# Must run as root: /var/lib/nextcloud is 0750 nextcloud:nextcloud, and only
# root can preserve ownership, ACLs and xattrs.

SRC=/var/lib/nextcloud
DEST_ROOT=/home/freerat/backups
# Staged OUTSIDE $DEST_ROOT on purpose. backup.sh derives the snapshot-set
# directory as <dest-root>/<basename of source>, so staging the dump at
# $DEST_ROOT/nextcloud-db would make the source and its own snapshot set the
# same directory. Keeping it outside also satisfies the rule that a database
# dump must not sit inside the Nextcloud data root, where Nextcloud would index
# it and the web server could serve it.
DB_STAGE=/var/backup/nextcloud-db
DB_NAME=nextcloud
BACKUP=/home/freerat/config_flake/scripts/backup.sh
OCC=nextcloud-occ

say()  { printf '\n\033[0;36m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m==> WARNING:\033[0m %s\n' "$*" >&2; }
die()  { printf '\n\033[0;31m==> FATAL:\033[0m %s\n' "$*" >&2; exit 2; }

[ "$(id -u)" -eq 0 ] || die "run this as root (sudo), or the backup silently skips every unreadable file"
[ -d "$SRC" ] || die "$SRC does not exist"
[ -x "$BACKUP" ] || die "$BACKUP not found or not executable"
command -v "$OCC" >/dev/null || die "$OCC not on PATH"
command -v pg_dump >/dev/null || command -v runuser >/dev/null || die "need pg_dump reachable (directly or via runuser -u postgres)"

mkdir -p "$DEST_ROOT"
install -d -m 0700 -o root -g root "$DB_STAGE" || die "cannot create $DB_STAGE"

say "Source size and free space"
du -sh "$SRC" 2>/dev/null | sed 's/^/    files:    /'
runuser -u postgres -- psql -tAc "select pg_size_pretty(pg_database_size('$DB_NAME'));" 2>/dev/null \
    | sed 's/^/    database: /' || echo "    database: (size query failed)"
df -h "$DEST_ROOT" | tail -1 | awk '{print "    target:   " $4 " free on " $6}'

MAINT_ON=false
cleanup() {
    if [ "$MAINT_ON" = true ]; then
        say "Turning maintenance mode OFF"
        if "$OCC" maintenance:mode --off; then
            MAINT_ON=false
        else
            warn "could not disable maintenance mode — do it by hand:"
            warn "    nextcloud-occ maintenance:mode --off"
        fi
    fi
}
# Always restore service, including on Ctrl-C or an unexpected error.
trap cleanup EXIT INT TERM

say "Pass 1 of 2: bulk file copy with the service still UP (no outage yet)"
"$BACKUP" create "$SRC" --dest-root "$DEST_ROOT" || die "pass 1 failed"

say "Turning maintenance mode ON (clients see a maintenance page from here)"
"$OCC" maintenance:mode --on || die "could not enable maintenance mode; refusing to take an inconsistent snapshot"
MAINT_ON=true

say "Pass 2 of 2: incremental file snapshot of the quiesced instance (--checksum)"
"$BACKUP" create "$SRC" --dest-root "$DEST_ROOT" --checksum || die "pass 2 failed"

say "Verifying the file snapshot against the live source, by content"
"$BACKUP" verify "$SRC" --dest-root "$DEST_ROOT"
FILES_RC=$?

say "Dumping PostgreSQL '$DB_NAME' in the same maintenance window"
DUMP="$DB_STAGE/$DB_NAME.dump"
DB_RC=0
DUMP_ERR=$(mktemp)
if runuser -u postgres -- pg_dump -Fc "$DB_NAME" > "$DUMP.tmp" 2>"$DUMP_ERR"; then
    mv -f -- "$DUMP.tmp" "$DUMP"
    chmod 0600 "$DUMP"
    printf '    wrote %s (%s)\n' "$DUMP" "$(du -h "$DUMP" | cut -f1)"

    # Validate the archive AS ROOT. pg_restore --list only reads a local file
    # and needs no database connection, and the dump is 0600 root:root inside a
    # 0700 root:root directory — running this as postgres fails with EACCES and
    # looks exactly like a corrupt dump.
    #
    # Cheap structural check first: a -Fc archive begins with the magic "PGDMP".
    if [ "$(head -c 5 -- "$DUMP")" != "PGDMP" ]; then
        warn "dump does not start with the PGDMP magic — not a custom-format archive"
        DB_RC=3
    else
        TOC_ERR=$(mktemp)
        if TOC=$(pg_restore --list "$DUMP" 2>"$TOC_ERR"); then
            printf '    PGDMP magic ok; pg_restore --list: %s objects\n' \
                "$(printf '%s\n' "$TOC" | grep -c '^[0-9]')"
        else
            # Show the real reason instead of asserting the dump is bad.
            warn "pg_restore --list failed:"
            sed 's/^/        /' "$TOC_ERR" >&2
            DB_RC=3
        fi
        rm -f -- "$TOC_ERR"
    fi

    # Record the server version — a custom-format dump restores into the same
    # major version or newer, not older. This one does need a connection.
    runuser -u postgres -- psql -tAc 'show server_version;' 2>/dev/null \
        | tr -d ' ' > "$DB_STAGE/postgres-version.txt" || true
    [ -s "$DB_STAGE/postgres-version.txt" ] \
        && printf '    postgres server_version: %s\n' "$(cat "$DB_STAGE/postgres-version.txt")"
else
    rm -f -- "$DUMP.tmp"
    warn "pg_dump failed:"
    sed 's/^/        /' "$DUMP_ERR" >&2
    DB_RC=2
fi
rm -f -- "$DUMP_ERR"

if [ "$DB_RC" -eq 0 ]; then
    say "Snapshotting the dump into the same store"
    "$BACKUP" create "$DB_STAGE" --dest-root "$DEST_ROOT" --checksum || DB_RC=2
    if [ "$DB_RC" -eq 0 ]; then
        say "Verifying the database snapshot"
        "$BACKUP" verify "$DB_STAGE" --dest-root "$DEST_ROOT"
        DB_RC=$?
    fi
fi

cleanup   # bring the service back before doing anything else

say "Dropping pass 1 (the inconsistent bulk snapshot), keeping the verified one"
"$BACKUP" prune "$SRC" --dest-root "$DEST_ROOT" --keep 1 || true

say "Result"
"$BACKUP" list "$SRC" --dest-root "$DEST_ROOT" || true
if [ -d "$DEST_ROOT/$(basename "$DB_STAGE")" ]; then
    "$BACKUP" list "$DB_STAGE" --dest-root "$DEST_ROOT" || true
else
    printf '    (no database snapshot — the dump did not pass its checks)\n'
fi

printf '\n'
if [ "$FILES_RC" -eq 0 ] && [ "$DB_RC" -eq 0 ]; then
    printf '\033[0;32m==> BACKUP VERIFIED\033[0m  files and database both match their sources\n'
    printf '    files:    %s/nextcloud/\n' "$DEST_ROOT"
    printf '    database: %s/nextcloud-db/\n' "$DEST_ROOT"
    printf '    both captured in one maintenance window, so they restore as a pair.\n'
    printf '\n    To restore (see upstream restore.html):\n'
    printf '      runuser -u postgres -- pg_restore -c -d %s <dump>\n' "$DB_NAME"
    printf '\n    NOTE: the snapshot was taken while maintenance mode was ON, and that\n'
    printf '    flag lives in config/config.php — so a restored instance comes up in\n'
    printf '    maintenance mode. Afterwards run:\n'
    printf '      nextcloud-occ maintenance:mode --off\n'
    exit 0
fi

printf '\033[0;31m==> NOT A VERIFIED BACKUP\033[0m  files verify=%s  database=%s\n' "$FILES_RC" "$DB_RC"
printf '    Read the output above. Do not rely on this as a pre-upgrade backup.\n'
[ "$FILES_RC" -eq 0 ] || printf '    Files: exit 3 means the snapshot is not an exact copy of the source.\n'
[ "$DB_RC" -eq 0 ] || printf '    Database: the dump failed, or failed its readability check.\n'
exit 1
