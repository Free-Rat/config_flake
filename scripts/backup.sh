#!/usr/bin/env bash
set -euo pipefail

# Incremental, restorable local backups using rsync --link-dest.
#
# Every run writes a full-looking snapshot tree, but files unchanged since the
# previous snapshot are hardlinks to it, so only the changes cost disk space.
# Snapshots are plain files: you can browse them with ls and restore with cp
# even if this script is gone.
#
# Because snapshots share inodes, anything that writes into a snapshot
# directory can corrupt its neighbours. Several guards below exist only to
# make that impossible; they are marked SHARED-INODE.

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

DEST_ROOT="${BACKUP_DEST_ROOT:-/var/backup}"
KEEP=0
DRY_RUN=false
CHECKSUM=false
ONE_FS=false
MIRROR=false
FORCE=false
NAME=""
NAME_GIVEN=false
EXCLUDES=()

log()  { printf "${CYAN}[backup]${NC} %s\n" "$*" >&2; }
ok()   { printf "${GREEN}[backup]${NC} %s\n" "$*" >&2; }
warn() { printf "${YELLOW}[backup]${NC} %s\n" "$*" >&2; }
die()  { printf "${RED}[backup] FATAL:${NC} %s\n" "$*" >&2; exit 2; }

usage() {
    cat <<EOF
backup.sh — incremental, restorable local backups (rsync hardlink snapshots)

Usage:
    $(basename "$0") create  <source-dir> [OPTIONS]
    $(basename "$0") verify  <source-dir> [snapshot] [OPTIONS]
    $(basename "$0") list    <source-dir|--name NAME> [OPTIONS]
    $(basename "$0") restore <source-dir|--name NAME> <snapshot> <target> [OPTIONS]
    $(basename "$0") prune   <source-dir|--name NAME> --keep N [OPTIONS]

'verify' always needs the live source directory, since that is what it compares
against; add --name as well if the set is not named after the source basename.

Options:
    -d, --dest-root DIR   Where snapshot sets live (default: $DEST_ROOT,
                          override with \$BACKUP_DEST_ROOT)
        --name NAME       Snapshot-set name (default: basename of the source)
    -k, --keep N          After create: keep only the N newest snapshots
    -e, --exclude PATTERN rsync exclude pattern; repeatable
    -c, --checksum        create only: compare file CONTENT, not size+mtime.
                          Slower, but catches a changed file whose size and
                          mtime are unchanged. Use it for a backup you intend
                          to rely on. 'verify' and 'restore' always compare
                          content, so this does nothing there.
    -x, --one-file-system Do not cross filesystem boundaries. Recorded in the
                          snapshot, since it can leave a whole subtree out.
        --mirror          restore only: also DELETE files at the target that the
                          snapshot does not have. Refuses a system root, a
                          non-empty target, and a PARTIAL or -x snapshot unless
                          --force. Note it passes --delete but not
                          --delete-excluded, so anything matched by --exclude
                          survives at the target.
        --force           restore only: proceed with a --mirror that would
                          otherwise be refused. Deletes live data.
    -n, --dry-run         Show what would happen, change nothing
    -h, --help            Show this help and exit

Exit codes:
    0  success
    2  usage error, or a refused operation
    3  verify found differences, or a snapshot recorded as PARTIAL or modified

So this gates on the backup actually being good:
    $(basename "$0") create /path --checksum && $(basename "$0") verify /path && <next step>

Layout ( <dest-root>/<name>/ ):
    2026-10-23T03-00-00/          a snapshot: a complete tree of the source
    2026-10-23T03-00-00.info      what that snapshot was and how the run went
    2026-10-23T03-00-00.excludes  its --exclude patterns, so verify can reuse
    latest -> 2026-10-23T...      symlink to the newest good snapshot
    .source                       the source path this set belongs to
    .incomplete/                  in-flight run; promoted to a snapshot on success

A run that dies leaves .incomplete behind and never touches 'latest'.

Examples:
    # back up Nextcloud data (needs root to read it and preserve ownership)
    sudo $(basename "$0") create /var/lib/nextcloud --keep 14

    # a backup you are about to bet on: compare contents, then check it
    sudo $(basename "$0") create /var/lib/nextcloud --checksum
    sudo $(basename "$0") verify /var/lib/nextcloud

    sudo $(basename "$0") list /var/lib/nextcloud

    # restore somewhere empty and inspect before swapping anything
    sudo $(basename "$0") restore /var/lib/nextcloud latest /var/tmp/nc-restore

Restoring: 'restore' copies files out and never hardlinks, so the restored
copy is independent of the snapshots. By default it merges into whatever is
already at the target and deletes nothing — so restoring an old snapshot on
top of a newer tree leaves you with BOTH sets of files, which for an
application directory is usually broken. To roll a directory back, restore to
an empty directory and swap it in:

    sudo $(basename "$0") restore /var/lib/nextcloud <snap> /var/tmp/nc-rollback
    systemctl stop phpfpm-nextcloud
    mv /var/lib/nextcloud /var/lib/nextcloud.bad && mv /var/tmp/nc-rollback /var/lib/nextcloud

Never write into a snapshot directory. Unchanged files are shared between
snapshots, so a chmod, chown or edit there silently changes every snapshot
holding that file. For this reason 'restore' refuses a target that is inside
the dest-root, and also one that CONTAINS it — mirroring onto a parent of the
snapshot store would delete every backup you have, including the one being
restored from.

What this does not promise:
    - Without --checksum, a file is considered unchanged when its size and
      mtime match, so a modification that preserves both is not noticed. Use
      --checksum for a backup you will rely on, and 'verify' to confirm it.
    - Directory mtimes come back accurate to the second, not the nanosecond
      (rsync preserves them that way). A sub-second difference on a directory
      is normal, not corruption. File mtimes are exact.
    - 'verify' detects accident, corruption and interrupted runs. It does NOT
      detect an adversary with write access to the dest-root: nothing here is
      signed, so someone who can rewrite a snapshot can rewrite the records
      that describe it. Protect <dest-root> with permissions accordingly.
    - A -x snapshot verified while the other filesystem is unmounted will pass,
      because nothing can then tell the subtree is missing. 'list' flags such
      snapshots -x, and --mirror refuses them without --force.
    - Snapshots taken before <stamp>.excludes existed have no patterns to
      reuse, so 'verify' on one needs its --exclude patterns repeated.
    - 'restore' refuses '/' as a target, since the guards treat it as an
      ancestor of the snapshot store. Restore elsewhere and move the result in.
    - The backup sits on the same disk as its source unless you point
      --dest-root elsewhere, so it defends against a bad upgrade, a deletion or
      an application corrupting its own data — not against losing the disk.
      Before anything irreversible, keep one independent copy by another route.

Databases:
    A file copy of a live database directory is NOT reliably restorable, and
    this script does not back up databases.

    For Nextcloud, follow the upstream procedure — this script only replaces its
    folder-copy step, with an incremental snapshot instead of a dated full copy:
    https://docs.nextcloud.com/server/stable/admin_manual/maintenance/backup.html

        nextcloud-occ maintenance:mode --on
        install -d -m 0700 /var/backup/nextcloud-db
        sudo -u postgres pg_dump -Fc nextcloud > /var/backup/nextcloud-db/nextcloud.dump
        sudo $(basename "$0") create /var/lib/nextcloud --checksum
        sudo $(basename "$0") verify /var/lib/nextcloud
        sudo $(basename "$0") create /var/backup/nextcloud-db
        nextcloud-occ maintenance:mode --off

    Maintenance mode is upstream's way of quiescing the instance and is gentler
    than stopping php-fpm: clients get a maintenance response rather than a hard
    error, and occ keeps working. Dump Postgres OUTSIDE the Nextcloud data root
    — a dump left inside it gets indexed by Nextcloud and served by the web
    server.

    Upstream lists five things to back up: config, custom apps, data, theme, and
    the database. On NixOS the first four all live under /var/lib/nextcloud
    (services.nextcloud.home, which is also the datadir here), so one snapshot
    of that path plus the dump covers all of it. Upstream also assumes you back
    up the Nextcloud installation directory; on NixOS that is in the nix store,
    so it is rebuilt from this flake rather than restored — pin
    services.nextcloud.package and the flake.lock entry instead.

    Files and database must be captured with nothing writing, or they describe
    two different instants and may not restore as a pair.

This backup lives on the same disk as its source, so it does not survive that
disk failing. It protects against deletion, corruption by an application, and
bad upgrades — not hardware loss.
EOF
}

# --- argument parsing ---------------------------------------------------------

[ $# -ge 1 ] || { usage; exit 2; }
case "${1:-}" in -h|--help) usage; exit 0 ;; esac

CMD="$1"; shift
case "$CMD" in
    create|verify|list|restore|prune) ;;
    *) die "unknown command '$CMD' (expected create, verify, list, restore or prune; --help for usage)" ;;
esac

SOURCE=""
POSITIONAL=()
while [ $# -gt 0 ]; do
    case "$1" in
        -d|--dest-root) [ $# -ge 2 ] || die "$1 needs a directory"; DEST_ROOT="$2"; shift 2 ;;
        --name)         [ $# -ge 2 ] || die "$1 needs a name";      NAME="$2"; NAME_GIVEN=true; shift 2 ;;
        -k|--keep)      [ $# -ge 2 ] || die "$1 needs a number";    KEEP="$2";      shift 2 ;;
        -e|--exclude)
            [ $# -ge 2 ] || die "$1 needs a pattern"
            # The patterns are stored one per line for verify to reuse, so a
            # newline would split one into two and trip verify's cross-check on
            # a perfectly good backup. An empty pattern excludes nothing and
            # silently disables that reuse.
            [ -n "$2" ] || die "--exclude needs a non-empty pattern"
            case "$2" in *$'\n'*) die "--exclude pattern must not contain a newline" ;; esac
            EXCLUDES+=( "--exclude=$2" ); shift 2 ;;
        -c|--checksum)  CHECKSUM=true; shift ;;
        -x|--one-file-system) ONE_FS=true; shift ;;
        --mirror)       MIRROR=true; shift ;;
        --force)        FORCE=true; shift ;;
        -n|--dry-run)   DRY_RUN=true; shift ;;
        -h|--help)      usage; exit 0 ;;
        --)             shift; while [ $# -gt 0 ]; do POSITIONAL+=( "$1" ); shift; done ;;
        -*)             die "unknown option '$1' (--help for usage)" ;;
        *)              POSITIONAL+=( "$1" ); shift ;;
    esac
done

if [ "$NAME_GIVEN" = true ] && [ -z "$NAME" ]; then die "--name must not be empty"; fi
[[ "$KEEP" =~ ^[0-9]+$ ]] || die "--keep needs a non-negative integer, got '$KEEP'"
[ "$MIRROR" = false ] || [ "$CMD" = restore ] || die "--mirror only applies to restore"
[ "$FORCE" = false ] || [ "$CMD" = restore ] || die "--force only applies to restore"
[ -n "$DEST_ROOT" ] || die "--dest-root must not be empty"
case "$DEST_ROOT" in /*) ;; *) die "--dest-root must be an absolute path, got '$DEST_ROOT'" ;; esac

# create and verify both need the live source itself, not just the set name, so
# they always consume the first positional argument. list/restore/prune only
# need it to derive the set name, and accept --name instead.
if [ "$CMD" = create ] || [ "$CMD" = verify ]; then
    [ "${#POSITIONAL[@]}" -ge 1 ] || die "$CMD needs a source directory"
    SOURCE="${POSITIONAL[0]}"
    POSITIONAL=( "${POSITIONAL[@]:1}" )
elif [ -z "$NAME" ]; then
    [ "${#POSITIONAL[@]}" -ge 1 ] || die "$CMD needs a source directory or --name NAME"
    SOURCE="${POSITIONAL[0]}"
    POSITIONAL=( "${POSITIONAL[@]:1}" )
fi

if [ -n "$SOURCE" ]; then
    # strip trailing slashes so the derived name is stable
    while [ "${SOURCE: -1}" = / ] && [ "${#SOURCE}" -gt 1 ]; do SOURCE="${SOURCE%/}"; done
    if [ -z "$NAME" ]; then
        NAME="$(basename -- "$SOURCE")"
        # The default name is only the basename, so two different sources can
        # land on it (/var/lib/nextcloud/data and /var/lib/postgresql/data both
        # give "data"). cmd_create refuses to mix sources in one set; the name
        # itself must still be usable as a directory name.
        [[ "$NAME" =~ ^[A-Za-z0-9_][A-Za-z0-9._+-]*$ ]] \
            || die "cannot derive a safe snapshot-set name from '$SOURCE' (got '$NAME'); pass --name NAME"
    fi
fi
[ -n "$NAME" ] || die "no snapshot-set name; pass --name NAME"
[[ "$NAME" =~ ^[A-Za-z0-9_][A-Za-z0-9._+-]*$ ]] \
    || die "invalid snapshot-set name '$NAME' (use letters, digits, . _ + - and do not start with . or -)"

JOBDIR="$DEST_ROOT/$NAME"
WORK="$JOBDIR/.incomplete"
LATEST="$JOBDIR/latest"
SRCFILE="$JOBDIR/.source"

# A completed snapshot, e.g. 2026-10-23T03-00-00. Nothing else in $JOBDIR
# (.incomplete, .source, .lock, latest, *.info) is a snapshot.
SNAP_GLOB='[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]-[0-9][0-9]-[0-9][0-9]'
snap_name_ok() { [[ "$1" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}-[0-9]{2}-[0-9]{2}$ ]]; }

# Read one key from a snapshot's .info. Last definition wins and exactly one
# line is returned: a `sed -n 's/^key=//p'` returning two lines made every
# `[ "$x" = true ]` test false, which turned a `partial=true` snapshot into one
# that passed the gate. Returns non-zero if the key is absent or has no value.
info_get() {
    local f="$1" k="$2" v
    [ -f "$f" ] || return 1
    v="$(awk -v k="$k" 'index($0, k "=") == 1 { v = substr($0, length(k) + 2); seen = 1 }
                        END { if (!seen) exit 1; print v }' "$f")" || return 1
    [ -n "$v" ] || return 1
    printf '%s' "$v"
}

# Completed snapshots, oldest first. ISO names sort chronologically.
snapshots() {
    local d had_nullglob=0
    shopt -q nullglob && had_nullglob=1
    shopt -s nullglob
    for d in "$JOBDIR"/$SNAP_GLOB; do
        # A real directory only: a symlink named like a snapshot would otherwise
        # let restore read, and prune account for, an arbitrary tree.
        [ -d "$d" ] && [ ! -L "$d" ] && basename -- "$d"
    done
    [ "$had_nullglob" -eq 1 ] || shopt -u nullglob
}

# Common rsync flags. --archive covers recursion, perms, times, symlinks,
# owner and group; the rest add what --archive leaves out.
base_rsync_args() {
    printf '%s\n' --archive --acls --xattrs --hard-links --sparse \
                  --numeric-ids --human-readable
    [ "$CHECKSUM" = true ] && printf '%s\n' --checksum
    [ "$ONE_FS" = true ] && printf '%s\n' --one-file-system
    return 0
}

# Resolve $LATEST to a usable snapshot, or empty. Refuses anything that is not
# a symlink to a real snapshot directory: a plain file or directory called
# 'latest' would otherwise be used as a --link-dest base and as a restore
# source. SHARED-INODE.
# Pass 'lenient' to get an empty answer instead of a fatal error for a junk
# 'latest'. 'list' does that, so the one command you would run to diagnose a
# broken set can still show you the snapshots.
resolve_latest() {
    local strict="${1:-strict}" target
    [ -e "$LATEST" ] || [ -L "$LATEST" ] || return 0
    if [ ! -L "$LATEST" ]; then
        [ "$strict" = lenient ] && return 0
        die "'$LATEST' exists but is not a symlink; refusing to use it. Remove or rename it."
    fi
    target="$(readlink -f -- "$LATEST" 2>/dev/null || true)"
    if [ -z "$target" ] || [ ! -d "$target" ] || [ -L "$target" ]; then
        return 0   # dangling, or not a real directory; caller decides
    fi
    # Must live in THIS set. A 'latest' pointing at another set handed back that
    # set's tree on restore and made create hardlink the new snapshot into it,
    # breaking the one-set-one-source invariant .source exists to enforce.
    case "$target" in
        "$(realpath -m -- "$JOBDIR")"/*) ;;
        *) return 0 ;;
    esac
    snap_name_ok "$(basename -- "$target")" || return 0
    printf '%s' "$target"
}

# --- create -------------------------------------------------------------------

cmd_create() {
    [ -e "$SOURCE" ] || die "source '$SOURCE' does not exist"
    [ -d "$SOURCE" ] || die "source '$SOURCE' is not a directory (this backs up directory trees, not single files)"
    [ -r "$SOURCE" ] || die "source '$SOURCE' is not readable by $(id -un) (try sudo)"
    command -v rsync >/dev/null || die "rsync not found in PATH"

    local src_real dest_real
    src_real="$(readlink -f -- "$SOURCE")"
    # .source and .info are line-oriented, so a newline in the source path can
    # inject extra key=value lines and override the real ones — a source named
    # with an embedded "partial=false" masked a PARTIAL snapshot from the gate.
    case "$src_real" in
        *$'\n'*) die "source path contains a newline; refusing (it would corrupt the snapshot metadata)" ;;
    esac
    # Backing a tree up into itself grows without bound, each run capturing the
    # previous one.
    dest_real="$(readlink -f -- "$DEST_ROOT" 2>/dev/null || printf '%s' "$DEST_ROOT")"
    case "$dest_real/" in
        "$src_real"/*) die "dest-root '$dest_real' is inside the source '$src_real'; the backup would capture itself" ;;
    esac
    # The other direction that recurses: the source IS this set's directory, or
    # lives inside it. Easy to hit by accident, because the set directory is
    # <dest-root>/<basename of source> — staging a dump at
    # <dest-root>/nextcloud-db and backing that up puts the snapshots inside
    # their own source, so the next run captures the previous ones.
    local job_real
    job_real="$(realpath -m -- "$JOBDIR")"
    if [ "$src_real" = "$job_real" ]; then
        die "source '$src_real' is this set's own snapshot directory; snapshots would be written inside their own source. Stage the source outside '$dest_real', or pass --name."
    fi
    case "$src_real/" in
        "$job_real"/*) die "source '$src_real' is inside this set's snapshot directory '$job_real'; the backup would capture itself. Stage the source outside '$dest_real', or pass --name." ;;
    esac

    if [ "$(id -u)" -ne 0 ]; then
        warn "not running as root: ownership, ACLs and xattrs will not be preserved,"
        warn "and unreadable files will be skipped. Re-run with sudo for a full backup."
    fi

    local -a rsync_args
    mapfile -t rsync_args < <(base_rsync_args)
    rsync_args+=( --delete --delete-excluded --info=stats2 )

    local base
    base="$(resolve_latest)"
    if [ -z "$base" ] && [ "$(snapshots | wc -l)" -gt 0 ]; then
        # Snapshots exist but 'latest' is missing or dangling. Without this the
        # run would silently make a full copy and, worse, take the resume path
        # below while .incomplete still shares inodes with a real snapshot.
        local newest
        newest="$(snapshots | tail -1)"
        warn "'latest' is missing or dangling but snapshots exist; re-pointing it at $newest"
        if [ "$DRY_RUN" = false ]; then
            ln -sfn -- "$newest" "$LATEST.tmp" && mv -Tf -- "$LATEST.tmp" "$LATEST"
            base="$(resolve_latest)"
        fi
    fi

    if [ -n "$base" ]; then
        rsync_args+=( "--link-dest=$base" )
        log "incremental against $(basename -- "$base")"
    else
        log "no previous snapshot — this run makes a full copy"
    fi
    rsync_args+=( "${EXCLUDES[@]+"${EXCLUDES[@]}"}" )

    if [ "$DRY_RUN" = true ]; then
        # Compare the source against the last snapshot directly. Writing into
        # $WORK even with --dry-run reported confusing errors and modelled the
        # wrong plan when a leftover .incomplete was present.
        log "dry run: would back up '$SOURCE' -> '$JOBDIR/<timestamp>'"
        [ -d "$WORK" ] && warn "dry run: a leftover .incomplete is present; the real run would deal with it first"
        local -a dry_args
        mapfile -t dry_args < <(base_rsync_args)
        dry_args+=( --delete --delete-excluded --dry-run --itemize-changes )
        dry_args+=( "${EXCLUDES[@]+"${EXCLUDES[@]}"}" )
        if [ -n "$base" ]; then
            log "changes since $(basename -- "$base"):"
            rsync "${dry_args[@]}" "$SOURCE/" "$base/" || true
        else
            local empty
            empty="$(mktemp -d)"
            trap 'rm -rf -- "$empty"' RETURN
            log "no previous snapshot; everything below would be copied:"
            rsync "${dry_args[@]}" "$SOURCE/" "$empty/" || true
        fi
        [ "$KEEP" -gt 0 ] && prune_to "$KEEP"
        return 0
    fi

    mkdir -p -- "$JOBDIR" || die "cannot create '$JOBDIR'"

    exec 9>"$JOBDIR/.lock" || die "cannot create lock file in '$JOBDIR'"
    flock -n 9 || die "another backup of '$NAME' is already running"

    # One set holds one source. Without this, two sources sharing a basename
    # silently interleave their snapshots in one set, and --delete wipes the
    # other one's files on every run.
    if [ -f "$SRCFILE" ]; then
        local recorded
        recorded="$(cat -- "$SRCFILE")"
        if [ "$recorded" != "$src_real" ]; then
            die "snapshot set '$NAME' already holds backups of '$recorded', not '$src_real'. Pass --name to use a different set."
        fi
    fi

    if [ -d "$WORK" ]; then
        # SHARED-INODE. A leftover .incomplete whose files are hardlinked into
        # an existing snapshot must never be rsynced into: an attribute-only
        # fix (chmod/chown/touch) lands on the shared inode and rewrites that
        # snapshot. Decide from .incomplete's own link counts, not from whether
        # 'latest' happens to resolve.
        # A source containing its own hardlinks also shows link counts above 1,
        # so only treat that as sharing when a snapshot actually exists to share
        # with. Otherwise the partial first full copy is ours alone and worth
        # keeping, which is the whole point of resuming.
        if [ "$(snapshots | wc -l)" -gt 0 ] \
           && find "$WORK" -type f -links +1 -print -quit 2>/dev/null | grep -q .; then
            warn "discarding leftover .incomplete: its files are shared with an existing snapshot"
            rm -rf -- "$WORK"
        else
            warn "resuming the interrupted first full backup from .incomplete"
        fi
    fi
    mkdir -p -- "$WORK" || die "cannot create '$WORK'"

    if [ -n "$base" ]; then
        # --link-dest cannot hardlink across filesystems; rsync silently copies
        # instead, so every "incremental" costs a full copy.
        local base_fs work_fs
        base_fs="$(stat -c %d -- "$base")"
        work_fs="$(stat -c %d -- "$WORK")"
        if [ "$base_fs" != "$work_fs" ]; then
            warn "'$base' and '$WORK' are on different filesystems: rsync cannot hardlink"
            warn "and this run will cost a full copy, not an increment."
        fi
    fi

    # 1-second timestamp granularity: wait rather than fail if a snapshot of
    # this second already exists.
    local stamp snap tries=0
    while :; do
        stamp="$(date +%Y-%m-%dT%H-%M-%S)"
        snap="$JOBDIR/$stamp"
        [ -e "$snap" ] || break
        tries=$(( tries + 1 ))
        [ "$tries" -le 3 ] || die "snapshot '$stamp' already exists"
        log "a snapshot for this second already exists; waiting"
        sleep 1
    done

    local started rc=0
    started="$(date +%s)"
    log "backing up '$SOURCE' -> '$snap'"
    rsync "${rsync_args[@]}" "$SOURCE/" "$WORK/" || rc=$?

    # 24 = source files vanished mid-run. Common on live data, and the rest of
    # the tree is sound, but the snapshot is by definition missing those files,
    # so it gets recorded as partial rather than silently treated as clean.
    local partial=false
    if [ "$rc" -eq 24 ]; then
        warn "some files vanished while copying (rsync 24): this snapshot is PARTIAL"
        partial=true
        rc=0
    fi
    if [ "$rc" -ne 0 ]; then
        # Nothing was ever completed in this set and nothing partial is worth
        # keeping, so leave no trace: a bare rmdir can never succeed with the
        # lock and work dir still there, and every later run would claim to be
        # "resuming" a run that produced nothing. Safe while we hold the flock,
        # and gated on there being no completed snapshot to lose.
        if [ "$(snapshots | wc -l)" -eq 0 ] \
           && ! find "$WORK" -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
            rm -rf -- "$WORK"
            rm -f -- "${JOBDIR:?}/.lock" "$SRCFILE"
            rmdir -- "$JOBDIR" 2>/dev/null || true
        fi
        die "rsync failed with exit code $rc; 'latest' unchanged"
    fi

    local elapsed files bytes
    elapsed=$(( $(date +%s) - started ))
    files="$(find "$WORK" -type f 2>/dev/null | wc -l)"
    bytes="$(du -sb -- "$WORK" 2>/dev/null | cut -f1)"

    printf '%s\n' "$src_real" > "$SRCFILE"
    # Flush before promoting, so a crash right after the rename cannot leave a
    # snapshot directory whose contents never reached the disk.
    sync -f -- "$WORK" 2>/dev/null || sync || true

    # Promote only now that rsync has succeeded: a snapshot directory existing
    # means the run finished.
    mv -- "$WORK" "$snap"
    {
        printf 'source=%s\n' "$src_real"
        printf 'snapshot=%s\n' "$stamp"
        printf 'finished=%s\n' "$(date -Iseconds)"
        printf 'duration_seconds=%s\n' "$elapsed"
        printf 'files=%s\n' "$files"
        printf 'bytes=%s\n' "$bytes"
        printf 'based_on=%s\n' "${base:+$(basename -- "$base")}"
        printf 'partial=%s\n' "$partial"
        printf 'checksum=%s\n' "$CHECKSUM"
        # A -x snapshot of a tree with a separately-mounted subdirectory is
        # missing that whole subtree, so it must not look like a full one.
        printf 'one_file_system=%s\n' "$ONE_FS"
        printf 'host=%s\n' "$(hostname)"
        printf 'rsync=%s\n' "$(rsync --version | head -1)"
        local e
        for e in ${EXCLUDES[@]+"${EXCLUDES[@]}"}; do printf 'exclude=%q\n' "${e#--exclude=}"; done
    } > "$JOBDIR/$stamp.info"

    # The same patterns, raw and one per line, for verify to reuse. The .info
    # copy above is %q-escaped for humans and would need eval to read back;
    # without this, verify compares with no excludes and reports every excluded
    # file as a difference, failing the gate on a perfectly good backup.
    if [ "${#EXCLUDES[@]}" -gt 0 ]; then
        local x
        for x in "${EXCLUDES[@]}"; do printf '%s\n' "${x#--exclude=}"; done \
            > "$JOBDIR/$stamp.excludes"
    fi

    # SHARED-INODE / D9: never clobber a non-symlink 'latest' with mv -T, which
    # fails on a directory after the snapshot is already promoted.
    if [ -e "$LATEST" ] && [ ! -L "$LATEST" ]; then
        warn "'$LATEST' is not a symlink; leaving it alone. Snapshot $stamp is good; fix 'latest' by hand."
    else
        ln -sfn -- "$stamp" "$LATEST.tmp"
        mv -Tf -- "$LATEST.tmp" "$LATEST" || { rm -f -- "$LATEST.tmp"; warn "could not update 'latest'"; }
    fi

    if [ "$partial" = true ]; then
        warn "snapshot $stamp done in ${elapsed}s but is PARTIAL — verify before relying on it"
    else
        ok "snapshot $stamp done in ${elapsed}s ($files files)"
    fi
    log "set now uses $(du -sh -- "$JOBDIR" 2>/dev/null | cut -f1) on disk across $(snapshots | wc -l) snapshot(s)"

    [ "$KEEP" -gt 0 ] && prune_to "$KEEP"
    return 0
}

# --- verify -------------------------------------------------------------------

# Compare a snapshot against the live source by content. Read-only: --dry-run
# means nothing is written to either side.
#
# EXIT CODE IS THE POINT. This exists so that
#     create --checksum && verify && <the irreversible thing>
# actually gates. Returning 0 after finding differences would make it a diff
# viewer that always says yes, so differences exit 3.
cmd_verify() {
    [ -d "$JOBDIR" ] || die "no snapshot set at '$JOBDIR'"
    [ -d "$SOURCE" ] || die "verify needs the live source directory to compare against"

    local snap
    snap="$(pick_snapshot "${POSITIONAL[0]:-latest}")"
    local stamp info rc=0
    stamp="$(basename -- "$snap")"
    info="$JOBDIR/$stamp.info"

    # A snapshot recorded as incomplete is not trustworthy regardless of how it
    # compares, so say so up front and fail even if the diff is clean.
    if [ -f "$info" ]; then
        if [ "$(info_get "$info" partial || true)" = true ]; then
            warn "$stamp is recorded PARTIAL: files vanished while it was being written"
            rc=3
        fi
        if [ "$(info_get "$info" one_file_system || true)" = true ]; then
            warn "$stamp was taken with --one-file-system: any separately-mounted"
            warn "subdirectory of the source is NOT in it"
        fi
        # Cheap self-check: catches a snapshot truncated after it was written,
        # which comparing against a live source cannot distinguish from drift.
        # "Cannot check" must not report the same success as "checked and fine",
        # so a missing or unusable files= fails rather than being skipped.
        local rec_files now_files
        now_files="$(find "$snap" -type f 2>/dev/null | wc -l)"
        if ! rec_files="$(info_get "$info" files)"; then
            warn "$stamp has no usable 'files=' record; cannot confirm it is unmodified"
            rc=3
        elif [ "$rec_files" != "$now_files" ]; then
            warn "$stamp holds $now_files files but was recorded with $rec_files: it has been modified since"
            rc=3
        fi
    else
        warn "$stamp has no .info file; cannot check it against what was recorded"
        rc=3
    fi

    local -a args
    CHECKSUM=true
    mapfile -t args < <(base_rsync_args)
    # --delete-excluded is LOAD-BEARING, not tidiness. It is what stops an
    # exclude pattern from hiding a difference: a pattern broad enough to hide
    # a source file also marks the snapshot's copy for deletion, so the file
    # reappears in the output as "deleting <path>" and the comparison still
    # fails. Remove it and a planted .excludes can disarm this check.
    args+=( --dry-run --itemize-changes --delete --delete-excluded )
    # Reuse the snapshot's own excludes when none were given, or every excluded
    # file reads as a difference and the gate fails on a good backup — which
    # teaches people to skip the gate.
    if [ "${#EXCLUDES[@]}" -eq 0 ] && [ -f "$JOBDIR/$stamp.excludes" ]; then
        local -a saved=()
        mapfile -t saved < "$JOBDIR/$stamp.excludes"
        local p
        for p in ${saved[@]+"${saved[@]}"}; do
            [ -n "$p" ] && EXCLUDES+=( "--exclude=$p" )
        done
        if [ "${#EXCLUDES[@]}" -gt 0 ]; then
            # Print them, not just a count: a pattern someone planted to narrow
            # the comparison should be visible to whoever reads this output.
            log "reusing ${#EXCLUDES[@]} exclude pattern(s) recorded with $stamp:"
            for p in "${EXCLUDES[@]}"; do log "    ${p#--exclude=}"; done
            # Cross-check against the copy in .info. They are written together,
            # so a mismatch means one of them was edited afterwards.
            local recorded
            recorded="$(grep -c '^exclude=' "$info" 2>/dev/null || true)"
            if [ -n "$recorded" ] && [ "$recorded" -ne "${#EXCLUDES[@]}" ]; then
                warn "$stamp.excludes holds ${#EXCLUDES[@]} pattern(s) but its .info records $recorded: one of them has been edited"
                rc=3
            fi
        fi
    fi
    args+=( "${EXCLUDES[@]+"${EXCLUDES[@]}"}" )

    log "comparing '$SOURCE' against $stamp by content (read-only)"
    local out
    out="$(rsync "${args[@]}" "$SOURCE/" "$snap/" 2>&1 || true)"
    if [ -n "$out" ]; then
        printf '%s\n' "$out"
        warn "differences listed above. Lines starting with '>' are files whose content"
        warn "differs; 'deleting' means the snapshot has files the source no longer does."
        warn "This is expected if the source changed since the snapshot was taken, but it"
        warn "means this snapshot is NOT a copy of the source as it is right now."
        rc=3
    elif [ "$rc" -eq 0 ]; then
        ok "$stamp matches '$SOURCE' exactly"
    fi
    return "$rc"
}

# --- prune --------------------------------------------------------------------

prune_to() {
    local keep="$1"
    local -a all
    mapfile -t all < <(snapshots)
    local total="${#all[@]}"
    if [ "$total" -le "$keep" ]; then
        log "$total snapshot(s), keeping $keep — nothing to prune"
        return 0
    fi

    # Never delete what 'latest' points at: that is the --link-dest base for
    # the next run and the default restore source.
    local keep_name=""
    local base
    base="$(resolve_latest)"
    [ -n "$base" ] && keep_name="$(basename -- "$base")"

    local drop=$(( total - keep )) s removed=0
    log "pruning up to $drop of $total snapshot(s), keeping the $keep newest"
    for s in "${all[@]:0:$drop}"; do
        if [ "$s" = "$keep_name" ]; then
            warn "keeping $s: it is what 'latest' points at"
            continue
        fi
        if [ "$DRY_RUN" = true ]; then
            log "dry run: would remove $s"
            continue
        fi
        # Safe despite sharing: removing a snapshot only drops its links.
        rm -rf -- "${JOBDIR:?}/${s:?}" "${JOBDIR:?}/${s:?}.info" "${JOBDIR:?}/${s:?}.excludes"
        log "removed $s"
        removed=$(( removed + 1 ))
    done
    [ "$DRY_RUN" = true ] || log "removed $removed snapshot(s)"

    # Snapshot-named symlinks are not snapshots (they are skipped everywhere
    # else), so nothing would ever clean them up. Remove the link only, never
    # what it points at.
    local had_nullglob=0 l
    shopt -q nullglob && had_nullglob=1
    shopt -s nullglob
    for l in "$JOBDIR"/$SNAP_GLOB; do
        if [ -L "$l" ]; then
            if [ "$DRY_RUN" = true ]; then
                log "dry run: would remove stray symlink $(basename -- "$l")"
            else
                rm -f -- "$l"
                warn "removed stray symlink $(basename -- "$l") (its target was left alone)"
            fi
        fi
    done
    [ "$had_nullglob" -eq 1 ] || shopt -u nullglob
    return 0
}

cmd_prune() {
    [ -d "$JOBDIR" ] || die "no snapshot set at '$JOBDIR'"
    [ "$KEEP" -gt 0 ] || die "prune needs --keep N with N greater than 0"
    prune_to "$KEEP"
}

# --- list ---------------------------------------------------------------------

cmd_list() {
    [ -d "$JOBDIR" ] || die "no snapshot set at '$JOBDIR'"
    local -a all
    mapfile -t all < <(snapshots)
    if [ "${#all[@]}" -eq 0 ]; then
        warn "no snapshots in '$JOBDIR'"
        if [ -d "$WORK" ]; then
            warn "an .incomplete run is present — no backup has ever completed"
        fi
        return 0
    fi

    [ -f "$SRCFILE" ] && log "set '$NAME' backs up $(cat -- "$SRCFILE")"

    # Lenient: a junk 'latest' must not stop list from showing the snapshots,
    # since list is what you run to find out what is wrong.
    local newest="" base
    base="$(resolve_latest lenient)"
    [ -n "$base" ] && newest="$(basename -- "$base")"
    if [ -e "$LATEST" ] && [ ! -L "$LATEST" ]; then
        warn "'$LATEST' exists but is not a symlink; create and restore will refuse it"
    fi

    local s info finished flags
    printf "%-22s %10s  %-26s %s\n" "SNAPSHOT" "FILES" "FINISHED" "FLAGS"
    for s in "${all[@]}"; do
        info="$JOBDIR/$s.info"
        finished="?"; flags=""
        if [ -f "$info" ]; then
            finished="$(info_get "$info" finished || printf '?')"
            [ "$(info_get "$info" partial || true)" = true ] && flags="PARTIAL "
            [ "$(info_get "$info" one_file_system || true)" = true ] && flags="${flags}-x "
            [ "$(info_get "$info" checksum || true)" = true ] && flags="${flags}checksummed "
        else
            flags="no-info "
        fi
        [ "$s" = "$newest" ] && flags="${flags}<- latest"
        printf "%-22s %10s  %-26s %s\n" \
            "$s" "$(find "$JOBDIR/$s" -type f 2>/dev/null | wc -l)" "$finished" "$flags"
    done
    echo
    log "$JOBDIR occupies $(du -sh -- "$JOBDIR" 2>/dev/null | cut -f1) on disk (shared files counted once)"
    if [ -z "$newest" ]; then
        warn "'latest' is missing or unusable — the next create will re-point it at the newest snapshot"
    fi
    if [ -d "$WORK" ]; then
        warn ".incomplete present — an earlier run was interrupted"
    fi
    return 0
}

# --- restore ------------------------------------------------------------------

# Resolve a user-supplied snapshot argument. Only 'latest' or a real snapshot
# name is accepted: without this, '.incomplete' (a known-partial tree) and
# '../..' both resolved to readable directories and were happily restored.
pick_snapshot() {
    local which="$1" snap
    if [ "$which" = latest ]; then
        snap="$(resolve_latest)"
        [ -n "$snap" ] || die "no usable 'latest' in '$JOBDIR' (run '$(basename "$0") list --name $NAME')"
    else
        snap_name_ok "$which" || die "'$which' is not a snapshot name (expected 'latest' or e.g. 2026-10-23T03-00-00)"
        snap="$JOBDIR/$which"
        [ -d "$snap" ] || die "snapshot '$which' not found in '$JOBDIR'"
        # A symlink with a snapshot-shaped name is not a snapshot.
        [ ! -L "$snap" ] || die "'$which' is a symlink, not a snapshot directory"
    fi
    printf '%s' "$snap"
}

cmd_restore() {
    [ "${#POSITIONAL[@]}" -ge 2 ] || die "restore needs a snapshot and a target directory"
    local target="${POSITIONAL[1]}"
    [ -d "$JOBDIR" ] || die "no snapshot set at '$JOBDIR'"

    local snap
    snap="$(pick_snapshot "${POSITIONAL[0]}")"

    # SHARED-INODE. Restoring into the dest-root writes into the snapshot set
    # itself; rsync's attribute fixes then travel through shared inodes into
    # snapshots the user never named.
    #
    # realpath -m canonicalises without requiring any component to exist.
    # readlink -f needs every component but the last, so a target two or more
    # levels below an existing directory escaped this check entirely.
    local target_real dest_real tgt_id
    target_real="$(realpath -m -- "$target")"
    dest_real="$(realpath -m -- "$DEST_ROOT")"
    tgt_id="$(stat -c '%d:%i' -- "$target_real" 2>/dev/null || true)"
    if [ "$target_real" = "$dest_real" ] || case "$target_real/" in "$dest_real"/*) true ;; *) false ;; esac; then
        die "refusing to restore into '$target': it resolves to '$target_real', inside the dest-root '$dest_real', which would corrupt other snapshots"
    fi
    # The symmetric case, and never overridable: a --mirror onto an ANCESTOR of
    # the dest-root deletes the whole snapshot store, including the snapshot
    # being restored from. One wrong path component away from the in-place
    # rollback habit.
    case "$dest_real/" in
        "$target_real"/*)
            die "refusing to restore into '$target': it resolves to '$target_real', which CONTAINS the dest-root '$dest_real'; with --mirror this would delete the whole snapshot store" ;;
    esac
    # Both checks above compare paths, and realpath resolves symlinks but NOT
    # mounts — so a bind mount of the snapshot store (or of any ancestor of it)
    # has a different path and is still the same directory. Two bounded walks by
    # device+inode close that, the same way the system-root check does.
    #
    # Changes to either walk must be tested with REAL BIND MOUNTS. Every
    # plain-path route is refused by the two checks above before reaching them,
    # so a path-only test exercises nothing here and will pass against code that
    # does not run.
    #
    # Upwards: is the target the dest-root, or anything containing it? Catches a
    # bind of the store's parent or grandparent. This one needs the target to
    # exist, since a path that does not exist yet cannot BE an existing
    # directory — hence the $tgt_id guard. Do NOT "fix" that by anchoring
    # $tgt_id at the nearest existing ancestor: for a legitimate new target
    # beside the store (dest-root /var/backup/sets, target
    # /var/backup/restore-tmp) the anchor is /var/backup, and this walk would
    # then refuse it.
    if [ -n "$tgt_id" ]; then
        local d="$dest_real" d_id
        while :; do
            if [ -e "$d" ]; then
                d_id="$(stat -c '%d:%i' -- "$d" 2>/dev/null || true)"
                if [ -n "$d_id" ] && [ "$d_id" = "$tgt_id" ]; then
                    die "refusing to restore into '$target': it is the same directory as '$d' (bind mount or equivalent), which holds the dest-root '$dest_real'; this would destroy the snapshot store"
                fi
            fi
            [ "$d" = / ] && break
            d="$(dirname -- "$d")"
        done
    fi

    # Downwards: is the target, or anything containing it, somewhere inside the
    # store? Catches a bind of the store, the set directory, or a single
    # snapshot — where writing corrupts snapshots through shared inodes, and
    # which needs neither --mirror nor --force to do damage.
    #
    # Deliberately NOT gated on $tgt_id. A restore target's leaf usually does
    # not exist yet, and creating a new directory inside a snapshot corrupts the
    # store just the same; gating this on the leaf existing skipped the check for
    # exactly the paths people type. The loop below already handles that — it
    # tests each level only if it exists and walks up to the ancestors, which is
    # what this check needs.
    #
    # Entries are "<dev>:<inode>|<path>". The separator must NOT be ':' — the id
    # already contains one, so ${entry%%:*} would yield just the device number
    # and the comparison could never match.
    local -a forbidden=()
    local p p_id s
    for p in "$dest_real" "$JOBDIR" "$WORK"; do
        [ -e "$p" ] || continue
        p_id="$(stat -c '%d:%i' -- "$p" 2>/dev/null || true)"
        [ -n "$p_id" ] && forbidden+=( "$p_id|$p" )
    done
    while read -r s; do
        [ -n "$s" ] || continue
        p_id="$(stat -c '%d:%i' -- "$JOBDIR/$s" 2>/dev/null || true)"
        [ -n "$p_id" ] && forbidden+=( "$p_id|$JOBDIR/$s" )
    done < <(snapshots)

    local t="$target_real" t_id entry
    while :; do
        if [ -e "$t" ]; then
            t_id="$(stat -c '%d:%i' -- "$t" 2>/dev/null || true)"
            if [ -n "$t_id" ]; then
                for entry in ${forbidden[@]+"${forbidden[@]}"}; do
                    if [ "$t_id" = "${entry%%|*}" ]; then
                        die "refusing to restore into '$target': it is inside '${entry#*|}' reached by a bind mount or equivalent, which would corrupt the snapshot store"
                    fi
                done
            fi
        fi
        [ "$t" = / ] && break
        t="$(dirname -- "$t")"
    done

    if [ "$(id -u)" -ne 0 ]; then
        warn "not running as root: restored files will be owned by $(id -un), not their original owners."
    fi

    local -a args
    # A restore is a one-off, correctness-critical operation, so it always
    # compares content. With the size+mtime quick check, an in-place --mirror
    # deleted the files the snapshot lacked while silently NOT overwriting
    # same-size same-mtime files — leaving a tree that was neither the old one
    # nor the new one, and reporting success.
    CHECKSUM=true
    mapfile -t args < <(base_rsync_args)
    args+=( --info=stats2 )
    if [ "$MIRROR" = true ]; then
        # --mirror deletes live files, using the snapshot as the authority for
        # what should exist. Everything below is about making sure that
        # authority is sound and the blast radius is what the user intended.
        local stamp info
        stamp="$(basename -- "$snap")"
        info="$JOBDIR/$stamp.info"

        # A PARTIAL snapshot is missing files by definition. Mirroring from one
        # deletes exactly the live files it failed to capture.
        if [ "$(info_get "$info" partial || true)" = true ]; then
            [ "$FORCE" = true ] || die "$stamp is recorded PARTIAL: files vanished while it was written, so --mirror would delete live files it never captured. Re-run with --force only if you are certain."
            warn "--force: mirroring from PARTIAL snapshot $stamp"
        fi
        if [ "$(info_get "$info" one_file_system || true)" = true ]; then
            [ "$FORCE" = true ] || die "$stamp was taken with --one-file-system, so it is missing any separately-mounted subdirectory and --mirror would delete it. Re-run with --force only if you are certain."
            warn "--force: mirroring from --one-file-system snapshot $stamp"
        fi

        # Never mirror onto a system root — as root that deletes the machine —
        # and never let --force override it. Checked by device+inode as well as
        # by path, because realpath resolves symlinks but not mounts: a bind
        # mount of / has a different path and is still /.
        local sysdir sys_id
        for sysdir in / /bin /boot /dev /etc /home /lib /lib64 /nix /opt /proc /root /run /sbin /srv /sys /usr /var; do
            [ -e "$sysdir" ] || continue
            if [ "$target_real" = "$sysdir" ]; then
                die "refusing to --mirror onto '$target_real': that would delete everything there that the snapshot does not contain"
            fi
            if [ -n "$tgt_id" ]; then
                sys_id="$(stat -c '%d:%i' -- "$sysdir" 2>/dev/null || true)"
                if [ -n "$sys_id" ] && [ "$tgt_id" = "$sys_id" ]; then
                    die "refusing to --mirror onto '$target_real': it is the same directory as '$sysdir' (bind mount or equivalent), and this would delete everything there"
                fi
            fi
        done

        # Mirroring onto an existing non-empty tree is the destructive case.
        # The documented rollback restores into an empty directory and swaps.
        if [ -d "$target_real" ] && find "$target_real" -mindepth 1 -print -quit 2>/dev/null | grep -q .; then
            [ "$FORCE" = true ] || die "'$target_real' is not empty and --mirror would delete everything in it that $stamp does not contain. Restore into an empty directory and swap it in, or pass --force."
            warn "--force: '$target_real' is not empty and its extra files WILL BE DELETED"
        fi

        args+=( --delete )
        # Name the resolved path: a target that is a symlink is followed, so the
        # deletions land in whatever it points at.
        warn "--mirror: files under '$target_real' that $stamp does not have WILL BE DELETED"
        if [ -L "$target" ]; then
            warn "note: '$target' is a symlink; the deletions apply to '$target_real'"
        fi
    fi
    [ "$DRY_RUN" = true ] && args+=( --dry-run --itemize-changes )

    log "restoring $(basename -- "$snap") -> '$target'"
    if [ "$DRY_RUN" = false ]; then
        mkdir -p -- "$target" || die "cannot create target '$target'"
    fi
    # No --link-dest: the restored tree is a real, independent copy.
    rsync "${args[@]}" "$snap/" "$target/" || die "restore failed"
    if [ "$DRY_RUN" = true ]; then
        log "dry run: nothing was written"
        return 0
    fi
    ok "restored into '$target'"
    if [ "$MIRROR" = false ]; then
        log "note: this merged into '$target' and deleted nothing. If you meant to"
        log "roll a directory back to this snapshot, restore into an empty directory"
        log "and swap it in, or re-run with --mirror."
    fi
    return 0
}

case "$CMD" in
    create)  cmd_create ;;
    verify)  cmd_verify ;;
    list)    cmd_list ;;
    restore) cmd_restore ;;
    prune)   cmd_prune ;;
esac
