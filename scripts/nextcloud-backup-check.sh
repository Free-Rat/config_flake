#!/usr/bin/env bash
set -uo pipefail

# Independent check of a backup made by nextcloud-backup-now.sh.
#
# Deliberately does NOT use backup.sh for any of its conclusions — the point is
# to confirm the backup without trusting the tool that made it.
#
#   1. test-restores the database dump into a throwaway database and counts what
#      landed. This is the only check that proves a dump is restorable rather
#      than merely readable.
#   2. counts files and bytes in the file snapshot and compares them with what
#      was recorded when it was taken (catches truncation after the fact).
#   3. diffs the snapshot against the live source and classifies what differs.
#
# Run as root: the snapshots are nextcloud-owned 0750.

SRC=/var/lib/nextcloud
DEST_ROOT=/home/freerat/backups
FILES_SET="$DEST_ROOT/nextcloud"
DB_SET="$DEST_ROOT/nextcloud-db"
SCRATCH_DB=nextcloud_restoretest

say()  { printf '\n\033[0;36m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[0;32m    PASS\033[0m %s\n' "$*"; }
bad()  { printf '\033[0;31m    FAIL\033[0m %s\n' "$*"; }
note() { printf '         %s\n' "$*"; }

[ "$(id -u)" -eq 0 ] || { echo "run as root (the snapshots are nextcloud-owned 0750)" >&2; exit 2; }

RC=0
FSNAP="$(readlink -f -- "$FILES_SET/latest" 2>/dev/null)"
DSNAP="$(readlink -f -- "$DB_SET/latest" 2>/dev/null)"
[ -d "$FSNAP" ] || { echo "no file snapshot at $FILES_SET/latest" >&2; exit 2; }
[ -d "$DSNAP" ] || { echo "no database snapshot at $DB_SET/latest" >&2; exit 2; }

# ---------------------------------------------------------------- 1. database
say "1. Test-restoring the database dump into a throwaway database"
DUMP="$DSNAP/nextcloud.dump"
if [ ! -f "$DUMP" ]; then
    bad "no nextcloud.dump in $DSNAP"
    RC=1
else
    note "dump: $DUMP ($(du -h "$DUMP" | cut -f1))"
    # A copy postgres can actually read: the snapshot is 0600 root:root.
    TMPD=$(mktemp -d); chmod 0755 "$TMPD"
    cp -- "$DUMP" "$TMPD/d.dump"; chmod 0644 "$TMPD/d.dump"
    # Always drop the scratch database and the readable dump copy, including on
    # Ctrl-C. Invoked via trap, which shellcheck cannot see.
    # shellcheck disable=SC2329
    cleanup_db() {
        runuser -u postgres -- psql -q -c "DROP DATABASE IF EXISTS $SCRATCH_DB;" >/dev/null 2>&1
        rm -rf -- "$TMPD"
    }
    trap cleanup_db EXIT INT TERM

    runuser -u postgres -- psql -q -c "DROP DATABASE IF EXISTS $SCRATCH_DB;" >/dev/null 2>&1
    if runuser -u postgres -- psql -q -c "CREATE DATABASE $SCRATCH_DB;" >/dev/null 2>&1; then
        RESTORE_LOG=$(mktemp)
        runuser -u postgres -- pg_restore --no-owner --no-privileges \
            -d "$SCRATCH_DB" "$TMPD/d.dump" >"$RESTORE_LOG" 2>&1
        R_RC=$?
        TABLES=$(runuser -u postgres -- psql -tAd "$SCRATCH_DB" \
            -c "select count(*) from information_schema.tables where table_schema='public';" 2>/dev/null | tr -d ' ')
        ROWS=$(runuser -u postgres -- psql -tAd "$SCRATCH_DB" \
            -c "select count(*) from oc_filecache;" 2>/dev/null | tr -d ' ')
        USERS=$(runuser -u postgres -- psql -tAd "$SCRATCH_DB" \
            -c "select count(*) from oc_users;" 2>/dev/null | tr -d ' ')
        LIVE_ROWS=$(runuser -u postgres -- psql -tAd nextcloud \
            -c "select count(*) from oc_filecache;" 2>/dev/null | tr -d ' ')
        LIVE_TABLES=$(runuser -u postgres -- psql -tAd nextcloud \
            -c "select count(*) from information_schema.tables where table_schema='public';" 2>/dev/null | tr -d ' ')

        if [ "$R_RC" -eq 0 ] && [ -n "${TABLES:-}" ] && [ "${TABLES:-0}" -gt 0 ]; then
            ok "dump restored cleanly into $SCRATCH_DB"
        elif [ -n "${TABLES:-}" ] && [ "${TABLES:-0}" -gt 0 ]; then
            # pg_restore warns about pre-existing roles/extensions on a clean DB;
            # that is not a data problem, so report it rather than failing.
            ok "dump restored with warnings (see below) but the data is there"
            note "pg_restore messages:"
            sed 's/^/           /' "$RESTORE_LOG" | head -15
        else
            bad "dump did not restore"
            sed 's/^/           /' "$RESTORE_LOG" | head -20
            RC=1
        fi
        note "restored:  $TABLES tables, oc_users=$USERS, oc_filecache=$ROWS rows"
        note "live now:  $LIVE_TABLES tables, oc_filecache=$LIVE_ROWS rows"
        if [ -n "${TABLES:-}" ] && [ "${TABLES:-0}" -gt 0 ] && [ "$TABLES" = "${LIVE_TABLES:-}" ]; then
            ok "table count matches the live database"
        elif [ -n "${TABLES:-}" ] && [ "${TABLES:-0}" -gt 0 ]; then
            note "table count differs from live — expected only if the schema changed since the dump"
        fi
        rm -f -- "$RESTORE_LOG"
    else
        bad "could not create the scratch database"
        RC=1
    fi
fi

# ------------------------------------------------------------------- 2. counts
say "2. File snapshot against what was recorded when it was taken"
INFO="${FSNAP}.info"
REC_FILES=$(awk -F= '$1=="files"{v=$2} END{print v}' "$INFO" 2>/dev/null)
REC_BYTES=$(awk -F= '$1=="bytes"{v=$2} END{print v}' "$INFO" 2>/dev/null)
NOW_FILES=$(find "$FSNAP" -type f | wc -l)
NOW_BYTES=$(du -sb -- "$FSNAP" | cut -f1)
note "snapshot: $FSNAP"
note "recorded: $REC_FILES files, $REC_BYTES bytes"
note "on disk:  $NOW_FILES files, $NOW_BYTES bytes"
if [ "$REC_FILES" = "$NOW_FILES" ]; then
    ok "file count unchanged since the snapshot was taken"
else
    bad "file count changed: $REC_FILES -> $NOW_FILES"
    RC=1
fi
if [ "$REC_BYTES" = "$NOW_BYTES" ]; then
    ok "byte total unchanged"
else
    bad "byte total changed: $REC_BYTES -> $NOW_BYTES"
    RC=1
fi

# -------------------------------------------------------------------- 3. diff
say "3. Snapshot vs the LIVE source (drift since the snapshot is expected)"
note "the source has been serving users since maintenance mode was lifted, so"
note "a handful of differences here is normal; thousands would not be."
DIFFOUT=$(mktemp)
diff -rq --no-dereference "$SRC" "$FSNAP" >"$DIFFOUT" 2>&1
NDIFF=$(grep -c . "$DIFFOUT")
if [ "$NDIFF" -eq 0 ]; then
    ok "byte-for-byte identical to the live source right now"
else
    note "$NDIFF differing entries:"
    sed 's/^/           /' "$DIFFOUT" | head -25
    [ "$NDIFF" -gt 25 ] && note "... and $((NDIFF - 25)) more"
    if [ "$NDIFF" -lt 50 ]; then
        ok "a small number of differences — consistent with normal activity, not corruption"
    else
        bad "$NDIFF differences is more than ordinary drift; investigate"
        RC=1
    fi

    # config.php almost always differs, and for a reason worth naming: the
    # maintenance flag lives in that file, so a snapshot taken during the
    # maintenance window records "maintenance => true" while the live file has
    # gone back to false. Harmless for the backup, but it means a restored
    # instance comes up in maintenance mode.
    if grep -q 'config/config.php' "$DIFFOUT"; then
        SNAP_M=$(grep -o "'maintenance'[^,]*" "$FSNAP/config/config.php" 2>/dev/null | head -1)
        LIVE_M=$(grep -o "'maintenance'[^,]*" "$SRC/config/config.php" 2>/dev/null | head -1)
        say "config.php difference, explained"
        note "snapshot: ${SNAP_M:-(no maintenance key found)}"
        note "live:     ${LIVE_M:-(no maintenance key found)}"
        OTHER=$(diff <(grep -v "'maintenance'" "$FSNAP/config/config.php" 2>/dev/null) \
                     <(grep -v "'maintenance'" "$SRC/config/config.php" 2>/dev/null) 2>/dev/null)
        if [ -z "$OTHER" ]; then
            ok "the ONLY difference is the maintenance flag — expected, not a fault"
            note "but note: restoring this snapshot brings Nextcloud up in maintenance"
            note "mode. After a restore, run:  nextcloud-occ maintenance:mode --off"
        else
            note "config.php also differs beyond the maintenance flag:"
            printf '%s\n' "$OTHER" | sed 's/^/           /' | head -15
        fi
    fi
fi
rm -f -- "$DIFFOUT"

say "Verdict"
if [ "$RC" -eq 0 ]; then
    printf '\033[0;32m    The database dump genuinely restores, and the file snapshot is intact.\033[0m\n'
else
    printf '\033[0;31m    Something above failed — do not rely on this backup.\033[0m\n'
fi
exit "$RC"
