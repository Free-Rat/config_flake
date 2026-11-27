#!/usr/bin/env bash
# Fake agents in every status, for working on the herdr terminal map
# (programs/herdr-app/mods/my-terminal-map).
#
#   herdr-agent-samples.sh up     make an "agent-samples" workspace full of them
#   herdr-agent-samples.sh down   close it again (and their sub-agents)
#
# Each sample reports its status the way real agents do: OSC 7501
# (`ESC ]7501;state=<word>:app=<name>[:kind=<why>][:msg=<base64>] BEL`).
# `app` picks the icon (claude-code, codex, pi). Nothing real runs.
set -euo pipefail

SPACE_NAME="agent-samples"
SELF="$(readlink -f "$0")"
# Where the samples start: a git repo, so the workspace shows a branch.
FOLDER="$(cd "$(dirname "$SELF")/.." && pwd)"

report() { # state app [kind] [msg]
  local fields="state=$1:app=$2"
  [ -n "${3:-}" ] && fields+=":kind=$3"
  [ -n "${4:-}" ] && fields+=":msg=$(printf %s "$4" | base64 -w0)"
  printf '\033]7501;%s\007' "$fields"
}

screen() { # app state msg
  local i # bash scoping is dynamic: without this the loop below clobbers cycle's i
  printf '\033]0;%s sample\007\033[2J\033[H' "$1"
  printf '\033[1m%s\033[0m  (sample agent, status: %s)\n\n' "$1" "$2"
  printf '> %s\n\n' "${3:-waiting for input}"
  for i in 1 2 3 4 5 6; do printf '  %s line %d of made-up output\n' "$1" "$i"; done
}

forever() { while :; do sleep 3600; done; }

# One fake agent: agent <state> <app> <kind> <msg> [sub-agent states...]
agent() {
  local state="$1" app="$2" kind="$3" msg="$4"; shift 4
  screen "$app" "$state" "$msg"
  report "$state" "$app" "$kind" "$msg"
  # Sub-agents: started from this terminal, so it is their parent; they end with it.
  for sub in "$@"; do
    hc run --bg --no-notify -- bash "$SELF" sub "$sub" >/dev/null
  done
  forever
}

# Goes working -> blocked -> done -> idle -> error, 10 s each, to watch changes.
cycle() {
  local states=(working blocked done idle error) i=0
  while :; do
    local s="${states[i % 5]}" kind=""
    [ "$s" = blocked ] && kind=question
    screen pi "$s" "cycling: now $s"
    report "$s" pi "$kind" "Cycling through every status ($s)"
    sleep 10
    i=$((i + 1))
  done
}

sub() {
  local kind=""
  [ "$1" = blocked ] && kind=permission
  report "$1" claude-code "$kind" "Sub-agent, $1"
  forever
}

argv() { # JSON argv for herdr-app: bash <this script> <args...>
  jq -cn --args '$ARGS.positional' bash "$SELF" "$@"
}

up() {
  if herdr-app ls | jq -e --arg n "$SPACE_NAME" '.spaces[] | select(.name == $n)' >/dev/null; then
    echo "$SPACE_NAME already exists; run: $0 down" >&2
    exit 2
  fi
  local space
  space=$(herdr-app do space.new --name "$SPACE_NAME" --folder "$FOLDER" \
    --argv "$(argv agent blocked claude-code permission 'Wants to run: rm -rf build/')" | jq -r .space)

  tab() { herdr-app do tab.new --space "$space" --folder "$FOLDER" --argv "$(argv "$@")" >/dev/null; }
  tab agent blocked codex question 'Which database should the cache use?'
  tab agent working claude-code '' 'Refactoring the parser' working blocked
  tab agent working pi '' 'Running the test suite' working working working
  tab agent done codex '' 'Finished: 12 files changed'
  tab agent idle claude-code '' ''
  tab agent error pi '' 'Build failed: exit code 101'
  tab cycle
  echo "Made workspace $SPACE_NAME ($space). Open the map (Ctrl+Esc) to see it."
}

down() {
  local ids
  ids=$(herdr-app ls | jq -r --arg n "$SPACE_NAME" '.spaces[] | select(.name == $n) | .id')
  [ -z "$ids" ] && { echo "No $SPACE_NAME workspace." ; exit 0; }
  for id in $ids; do
    herdr-app do space.close --id "$id" --confirmed true >/dev/null
    echo "Closed $SPACE_NAME ($id)."
  done
}

case "${1:-}" in
  up) up ;;
  down) down ;;
  agent) shift; agent "$@" ;;
  cycle) cycle ;;
  sub) sub "$2" ;;
  *) echo "usage: $0 up|down" >&2; exit 2 ;;
esac
