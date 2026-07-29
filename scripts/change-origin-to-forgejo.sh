#!/usr/bin/env bash

set -eu

repo_root=$(git rev-parse --show-toplevel)
repo_name=$(basename "$repo_root")
forgejo_origin="ssh://forgejo@git.free-rat.dev:2223/Free-Rat/${repo_name}.git"

git remote set-url origin "$forgejo_origin"
printf 'origin changed to %s\n' "$forgejo_origin"
