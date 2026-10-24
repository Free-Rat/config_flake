#!/usr/bin/env bash
set -uo pipefail

# Repair PostgreSQL collation-version mismatches.
#
# When glibc changes (e.g. a nixpkgs bump), its collation rules can change too.
# PostgreSQL records the collation version a database was built with, and warns
# when the OS now provides a different one:
#
#   WARNING: database "x" has a collation version mismatch
#   DETAIL:  created using collation version 2.42, OS provides 2.44
#
# This is not cosmetic. Indexes on text columns are stored in collation order,
# so an index built under the old rules can disagree with the new ones, and
# queries that use it may silently return incomplete results.
#
# ORDER MATTERS: REINDEX first, then ALTER DATABASE ... REFRESH COLLATION
# VERSION. Refreshing first just records "this database is fine" over indexes
# that may still be wrong, and loses the only signal that anything needs doing.
#
# Nextcloud is put into maintenance mode while its own database is reindexed,
# because REINDEX takes locks that would otherwise surface as errors to users.
#
# Run as root. Pass --check to report without changing anything.

OCC=nextcloud-occ
NEXTCLOUD_DB=nextcloud

say()  { printf '\n\033[0;36m==>\033[0m %s\n' "$*"; }
ok()   { printf '\033[0;32m    PASS\033[0m %s\n' "$*"; }
bad()  { printf '\033[0;31m    FAIL\033[0m %s\n' "$*"; }
note() { printf '         %s\n' "$*"; }
die()  { printf '\n\033[0;31m==> FATAL:\033[0m %s\n' "$*" >&2; exit 2; }

CHECK_ONLY=false
[ "${1:-}" = "--check" ] && CHECK_ONLY=true

[ "$(id -u)" -eq 0 ] || die "run as root"
command -v runuser >/dev/null || die "runuser not found"

psql_() { runuser -u postgres -- psql -X -q -tA "$@"; }

say "PostgreSQL version"
SRV=$(psql_ -c 'show server_version;' 2>/dev/null | tr -d ' ')
[ -n "$SRV" ] || die "cannot reach PostgreSQL as the postgres user"
note "server_version: $SRV"

# pg_database_collation_actual_version() needs PG 15+. Without it we cannot tell
# which databases are stale, so refuse rather than guess.
HAVE_FN=$(psql_ -c "select count(*) from pg_proc where proname='pg_database_collation_actual_version';" 2>/dev/null | tr -d ' ')
[ "${HAVE_FN:-0}" -ge 1 ] || die "this PostgreSQL has no pg_database_collation_actual_version(); upgrade or fix by hand"

say "Databases with a collation version mismatch"
MISMATCH=$(psql_ -c "
  select datname
  from pg_database
  where datallowconn
    and datcollversion is not null
    and datcollversion <> pg_database_collation_actual_version(oid);
" 2>/dev/null)

psql_ -c "
  select datname || '  recorded=' || coalesce(datcollversion,'(none)') ||
         '  actual=' || coalesce(pg_database_collation_actual_version(oid),'(none)')
  from pg_database where datallowconn order by datname;
" 2>/dev/null | sed 's/^/         /'

if [ -z "$MISMATCH" ]; then
    ok "no mismatches — nothing to do"
    exit 0
fi

printf '\n'
note "to repair:"
printf '%s\n' "$MISMATCH" | sed 's/^/           - /'

if [ "$CHECK_ONLY" = true ]; then
    say "--check given: stopping here, nothing changed"
    exit 0
fi

RC=0
MAINT_ON=false
cleanup() {
    if [ "$MAINT_ON" = true ]; then
        say "Turning Nextcloud maintenance mode OFF"
        "$OCC" maintenance:mode --off || note "could not disable maintenance mode — run: nextcloud-occ maintenance:mode --off"
        MAINT_ON=false
    fi
}
trap cleanup EXIT INT TERM

# Quiesce Nextcloud if its database is among those needing work. REINDEX takes
# an ACCESS EXCLUSIVE lock per index, which a live instance would hit as errors.
if printf '%s\n' "$MISMATCH" | grep -qx "$NEXTCLOUD_DB" && command -v "$OCC" >/dev/null; then
    say "Nextcloud's database needs reindexing — enabling maintenance mode first"
    if "$OCC" maintenance:mode --on; then
        MAINT_ON=true
    else
        die "could not enable maintenance mode; refusing to REINDEX a live instance"
    fi
fi

while IFS= read -r db; do
    [ -n "$db" ] || continue
    say "Repairing '$db'"

    note "REINDEX DATABASE $db  (rebuilds indexes under the current collation)"
    if runuser -u postgres -- psql -X -q -d "$db" -c "REINDEX DATABASE \"$db\";" 2>&1 | sed 's/^/           /'; then
        ok "reindexed"
    else
        bad "REINDEX failed for '$db' — NOT refreshing its collation version"
        RC=1
        continue
    fi

    note "ALTER DATABASE $db REFRESH COLLATION VERSION"
    if runuser -u postgres -- psql -X -q -c "ALTER DATABASE \"$db\" REFRESH COLLATION VERSION;" 2>&1 | sed 's/^/           /'; then
        ok "collation version refreshed"
    else
        bad "refresh failed for '$db'"
        RC=1
    fi
done <<< "$MISMATCH"

cleanup

say "Verifying"
LEFT=$(psql_ -c "
  select datname
  from pg_database
  where datallowconn
    and datcollversion is not null
    and datcollversion <> pg_database_collation_actual_version(oid);
" 2>/dev/null)
if [ -z "$LEFT" ]; then
    ok "no collation mismatches remain"
else
    bad "still mismatched:"
    printf '%s\n' "$LEFT" | sed 's/^/           - /'
    RC=1
fi

if command -v "$OCC" >/dev/null; then
    note "Nextcloud status:"
    "$OCC" status 2>&1 | sed 's/^/           /'
fi

printf '\n'
if [ "$RC" -eq 0 ]; then
    printf '\033[0;32m==> DONE\033[0m  indexes rebuilt and collation versions refreshed\n'
else
    printf '\033[0;31m==> FINISHED WITH ERRORS\033[0m  see above\n'
fi
exit "$RC"
