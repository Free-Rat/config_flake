#!/bin/bash

set -euo pipefail

SKIP_DEFAULT=(.cache .ssh .local .mozilla .npm .cargo .rustup .gradle .thumbnails .dbus .pki .gnupg .config)
NO_SKIP=false
ROOT_DIR="$HOME"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS] [DIRECTORY]

Find highest-level directories that are not git repos and don't contain any
git repos recursively. Useful for identifying data not backed by git during
home directory backups.

Options:
  --no-skip    Don't skip conventional directories
  -h, --help   Show this help

Default target: \$HOME
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --no-skip) NO_SKIP=true ;;
        -h|--help) usage ;;
        *) ROOT_DIR="$1" ;;
    esac
    shift
done

if [[ ! -d "$ROOT_DIR" ]]; then
    echo "Error: $ROOT_DIR is not a directory" >&2
    exit 1
fi

ROOT_DIR="$(realpath "$ROOT_DIR")"

declare -A has_git
declare -A is_git_repo

while IFS= read -r gitdir; do
    repo_dir="$(dirname "$gitdir")"
    is_git_repo["$repo_dir"]=1
    ancestor="$repo_dir"
    while [[ "$ancestor" != "$ROOT_DIR" && "$ancestor" != "/" ]]; do
        has_git["$ancestor"]=1
        ancestor="$(dirname "$ancestor")"
    done
    has_git["$ROOT_DIR"]=1
done < <(find -P "$ROOT_DIR" -name .git -print 2>/dev/null)

should_skip() {
    local base
    base="$(basename "$1")"
    for skip in "${SKIP_DEFAULT[@]}"; do
        [[ "$base" == "$skip" ]] && return 0
    done
    return 1
}

walk() {
    local dir="$1"

    if [[ "$NO_SKIP" != true ]] && should_skip "$dir"; then
        return
    fi

    if [[ -z "${has_git[$dir]:-}" ]]; then
        echo "$dir"
        return
    fi

    if [[ -n "${is_git_repo[$dir]:-}" ]]; then
        return
    fi

    shopt -s dotglob nullglob
    local sub
    for sub in "$dir"/*/; do
        sub="${sub%/}"
        [[ "$(basename "$sub")" == "." || "$(basename "$sub")" == ".." ]] && continue
        [[ -L "$sub" ]] && continue
        [[ -d "$sub" ]] && walk "$sub"
    done
    shopt -u dotglob nullglob
}

walk "$ROOT_DIR"
