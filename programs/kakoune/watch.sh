#!/usr/bin/env bash

# echo $PATH_PROGRAMS # $PATH_WALLPAPERS $PATH_FLAKE_CONFIG $PATH_SCRIPTS

base="$PATH_PROGRAMS/kakoune"

conf_path="$HOME/.config"

p_rc="$base/kakrc"
p_lsp="$base/kak-lsp.toml"
p_ts="$base/kak-tree-sitter.toml"

c_rc="$conf_path/kak"
c_lsp="$conf_path/kak-lsp"
c_ts="$conf_path/kak-treesitter"

mkdir "$c_rc"
mkdir "$c_lsp"
mkdir "$c_ts"

echo "watching $p_rc"
echo "$p_rc" | entr cp "$p_rc" "$c_rc" &

echo "watching $p_lsp"
echo "$p_lsp" | entr cp "$p_lsp" "$c_lsp" &

echo "watching $p_ts"
echo "$p_ts" | entr cp "$p_ts" "$c_ts" &
