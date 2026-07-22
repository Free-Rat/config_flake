#!/usr/bin/env bash
set -euo pipefail

FORGEJO_URL="${FORGEJO_URL:-https://git.free-rat.dev}"
FORGEJO_OWNER="${FORGEJO_OWNER:-Free-Rat}"
FORGEJO_API="${FORGEJO_URL}/api/v1"

GITHUB_OWNER="${GITHUB_OWNER:-Free-Rat}"
MODE=""
REPO_NAME=""
NO_GITHUB_MIRROR=false
DELETE_GH_REMOTE=false
DRY_RUN=false
PRIVATE=false
PRIVATE_EXPLICIT=false

FORGEJO_TOKEN="${FORGEJO_TOKEN:-}"
GITHUB_TOKEN="${GITHUB_TOKEN:-}"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m'

die()  { echo -e "${RED}Error: $*${NC}" >&2; exit 1; }
info() { echo -e "${GREEN}→${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC} $*"; }
step() { echo -e "\n${BOLD}==>${NC} $*"; }

usage() {
    cat <<EOF
Usage: $(basename "$0") --personal|--add-forgejo-origin|--public [OPTIONS]

Migrate the current git repo to Forgejo (${FORGEJO_URL}).
Run from inside the git repo you want to migrate.

Modes:
  --personal           Forgejo becomes the new origin remote.
                       Optional: GitHub push mirror on Forgejo (default unless --no-github-mirror).
  --add-forgejo-origin  Add Forgejo as a remote (forgejo) alongside origin.
                       Pushes all refs to Forgejo and sets up GitHub push mirror.
                       Leaves origin untouched.
  --public             GitHub stays primary. Forgejo pulls from GitHub + pushes back.
                       Creates repo on Forgejo via migrate API; local clone is not modified.

Options:
  --forgejo-token TOKEN   Forgejo API token (or set FORGEJO_TOKEN env var)
  --github-token TOKEN    GitHub personal access token (or set GITHUB_TOKEN)
  --forgejo-owner OWNER   Forgejo user/org (default: ${FORGEJO_OWNER})
  --github-owner OWNER    GitHub user/org (default: ${GITHUB_OWNER})
  --repo-name NAME        Override repo name (default: inferred from origin)
  --no-github-mirror      Skip GitHub push mirror (personal / add-forgejo-origin modes)
  --delete-github-remote  Remove GitHub remote after migration (personal mode)
  --private               Create repo as private (default: public)
  --dry-run               Show planned actions, don't execute
  -h, --help              Show this help

Environment:
  FORGEJO_TOKEN   Forgejo API token  → ${FORGEJO_URL}/user/settings/applications
                   Scopes: read:repository, write:repository
  GITHUB_TOKEN    GitHub PAT        → https://github.com/settings/tokens
                   Scopes: repo (private) or public_repo (public)
EOF
    exit 0
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --personal)             MODE=personal ;;
        --add-forgejo-origin)   MODE=add-forgejo ;;
        --public)               MODE=public ;;
        --forgejo-token)        FORGEJO_TOKEN="$2"; shift ;;
        --github-token)         GITHUB_TOKEN="$2"; shift ;;
        --forgejo-owner)        FORGEJO_OWNER="$2"; shift ;;
        --github-owner)         GITHUB_OWNER="$2"; shift ;;
        --repo-name)            REPO_NAME="$2"; shift ;;
        --no-github-mirror)     NO_GITHUB_MIRROR=true ;;
        --delete-github-remote) DELETE_GH_REMOTE=true ;;
        --private)              PRIVATE=true; PRIVATE_EXPLICIT=true ;;
        --dry-run)              DRY_RUN=true ;;
        -h|--help)              usage ;;
        *)                      die "Unknown option: $1" ;;
    esac
    shift
done

[[ -z "$MODE"         ]] && die "Must specify --personal, --add-forgejo-origin, or --public"
[[ -z "$FORGEJO_TOKEN" ]] && die "Forgejo token required. Use --forgejo-token or set FORGEJO_TOKEN"

if [[ -n "$GITHUB_TOKEN" ]]; then
    echo -e "${YELLOW}Note:${NC} GitHub token will be sent to and stored on Forgejo server for mirroring."
fi

if ! git rev-parse --git-dir >/dev/null 2>&1; then
    die "Not inside a git repository. Run this from the repo you want to migrate."
fi

if [[ -z "$REPO_NAME" ]]; then
    ORIGIN_URL=$(git remote get-url origin 2>/dev/null || true)
    if [[ -n "$ORIGIN_URL" ]]; then
        REPO_NAME=$(basename "$ORIGIN_URL" .git)
    else
        REPO_NAME=$(basename "$(git rev-parse --show-toplevel)")
    fi
fi

FORGEJO_REMOTE="ssh://forgejo@${FORGEJO_URL#https://}:2223/${FORGEJO_OWNER}/${REPO_NAME}.git"
GITHUB_REMOTE="https://github.com/${GITHUB_OWNER}/${REPO_NAME}.git"

if [[ "$PRIVATE_EXPLICIT" == false && -n "$GITHUB_TOKEN" ]]; then
    if [[ "$DRY_RUN" == true ]]; then
        echo "  [DRY-RUN] Would check GitHub visibility for ${GITHUB_OWNER}/${REPO_NAME}"
    else
        if curl -s -H "Authorization: token ${GITHUB_TOKEN}" \
            "https://api.github.com/repos/${GITHUB_OWNER}/${REPO_NAME}" | grep -q '"private": *true'; then
            PRIVATE=true
            info "GitHub repo is private → Forgejo repo will be private"
        fi
    fi
fi

echo -e "${BOLD}Repo:${NC}    ${REPO_NAME}"
echo -e "${BOLD}Mode:${NC}    ${MODE}"
echo -e "${BOLD}Forgejo:${NC}  ${FORGEJO_URL}/${FORGEJO_OWNER}/${REPO_NAME}"
if [[ "$MODE" == "personal" ]]; then
    echo -e "${BOLD}New origin:${NC} ${FORGEJO_REMOTE}"
elif [[ "$MODE" == "add-forgejo" ]]; then
    echo -e "${BOLD}Adding remote:${NC} forgejo → ${FORGEJO_REMOTE}"
elif [[ "$MODE" == "public" ]]; then
    echo -e "${BOLD}GitHub:${NC}    ${GITHUB_REMOTE}"
fi
[[ "$DRY_RUN" == true ]] && echo -e "\n${YELLOW}DRY RUN — no changes will be made${NC}"

api() {
    local method="$1" url="$2" data="${3:-}"

    if [[ "$DRY_RUN" == true ]]; then
        local display_data=""
        [[ -n "$data" ]] && display_data=" -d '${data}'"
        echo "  [DRY-RUN] curl -s -X ${method} '${FORGEJO_API}${url}'${display_data}"
        return 0
    fi

    local response http_code
    response=$(curl -s -w "\n%{http_code}" -X "$method" "${FORGEJO_API}${url}" \
        -H "Authorization: token ${FORGEJO_TOKEN}" \
        -H "Content-Type: application/json" \
        ${data:+-d "$data"})

    http_code=$(echo "$response" | tail -1)

    if [[ "$http_code" =~ ^2 ]]; then
        return 0
    else
        echo "  HTTP ${http_code}: $(echo "$response" | sed '$d')" >&2
        return 1
    fi
}

repo_exists() {
    if [[ "$DRY_RUN" == true ]]; then
        echo "  [DRY-RUN] Check if repo ${FORGEJO_OWNER}/${REPO_NAME} exists (assuming it does not)"
        return 1
    fi
    local code
    code=$(curl -s -o /dev/null -w "%{http_code}" \
        "${FORGEJO_API}/repos/${FORGEJO_OWNER}/${REPO_NAME}" \
        -H "Authorization: token ${FORGEJO_TOKEN}")
    [[ "$code" == "200" ]]
}

forgejo_create_and_push() {
    step "Creating repo on Forgejo"
    if repo_exists; then
        warn "Repo ${FORGEJO_OWNER}/${REPO_NAME} already exists on Forgejo, skipping."
    else
        api POST "/user/repos" "{\"name\":\"${REPO_NAME}\",\"private\":${PRIVATE}}" ||
            die "Failed to create repo on Forgejo"
        info "Created: ${FORGEJO_URL}/${FORGEJO_OWNER}/${REPO_NAME}"
    fi

    step "Pushing all refs to Forgejo"
    if ! git remote get-url forgejo >/dev/null 2>&1; then
        if [[ "$DRY_RUN" == true ]]; then
            echo "  [DRY-RUN] git remote add forgejo ${FORGEJO_REMOTE}"
        else
            git remote add forgejo "$FORGEJO_REMOTE"
        fi
    fi
    if [[ "$DRY_RUN" == false ]]; then
        git push --all forgejo  || warn "No branches to push (empty repo?)"
        git push --tags forgejo || warn "Tag push failed (no tags, or network/auth error)"
    else
        echo "  [DRY-RUN] git push --all forgejo"
        echo "  [DRY-RUN] git push --tags forgejo"
    fi
    info "Pushed to Forgejo"
}

setup_github_push_mirror() {
    if [[ "$NO_GITHUB_MIRROR" == false ]]; then
        step "GitHub push mirror on Forgejo"
        if [[ -n "$GITHUB_TOKEN" ]]; then
            api POST "/repos/${FORGEJO_OWNER}/${REPO_NAME}/push_mirrors" \
                "{\"remote_address\":\"${GITHUB_REMOTE}\",\"remote_name\":\"github\",\"remote_username\":\"${GITHUB_OWNER}\",\"remote_password\":\"${GITHUB_TOKEN}\",\"interval\":\"8h0m0s\"}" &&
                info "Push mirror added → pushes to Forgejo will sync to GitHub" ||
                warn "Failed. Add manually: Forgejo repo → Settings → Mirror → Push mirror → ${GITHUB_REMOTE}"
        else
            warn "No GITHUB_TOKEN — skipping push mirror."
            warn "Add manually: repo Settings → Mirror → Push mirror → ${GITHUB_REMOTE}"
        fi
    fi
}

do_personal() {
    forgejo_create_and_push

    step "Setting origin to Forgejo"
    local old_origin
    old_origin=$(git remote get-url origin 2>/dev/null || true)
    if [[ "$DRY_RUN" == true ]]; then
        echo "  [DRY-RUN] git remote set-url origin ${FORGEJO_REMOTE}"
    else
        git remote set-url origin "$FORGEJO_REMOTE"
    fi
    info "origin → ${FORGEJO_REMOTE}"

    if [[ "$DELETE_GH_REMOTE" == true ]]; then
        step "Removing GitHub remote"
        local gh_remote=""
        if git remote get-url github >/dev/null 2>&1; then
            gh_remote="github"
        elif [[ "$old_origin" == *github.com* ]]; then
            warn "origin was github.com but has been changed to Forgejo — nothing to delete"
        fi
        if [[ -n "$gh_remote" ]]; then
            if [[ "$DRY_RUN" == false ]]; then
                git remote remove "$gh_remote"
            fi
            info "Removed '${gh_remote}' remote"
        fi
    fi

    setup_github_push_mirror
}

do_add_forgejo() {
    forgejo_create_and_push
    info "origin untouched → still points to $(git remote get-url origin 2>/dev/null || echo 'none')"
    setup_github_push_mirror
}

do_public() {
    step "Creating pull mirror on Forgejo from GitHub"

    if repo_exists; then
        warn "Repo already exists on Forgejo, skipping mirror setup."
        warn "To convert to mirror, use Forgejo UI: Settings → Mirror Settings."
    else
        local clone_addr="https://github.com/${GITHUB_OWNER}/${REPO_NAME}.git"
        local auth_json=""
        if [[ -n "$GITHUB_TOKEN" ]]; then
            auth_json=",\"auth_token\":\"${GITHUB_TOKEN}\""
        fi

        api POST "/repos/migrate" \
            "{\"clone_addr\":\"${clone_addr}\",\"mirror\":true,\"repo_name\":\"${REPO_NAME}\",\"mirror_interval\":\"8h0m0s\"${auth_json}}" ||
            die "Failed to create pull mirror"

        info "Pull mirror created — auto-syncs from GitHub every 8 hours"
    fi

    echo ""
    warn "Pull-mirrored repos may be read-only on Forgejo by default."
    echo "  If direct pushes to Forgejo are desired, create a normal repo instead"
    echo "  and use push mirrors on both sides."
}

case "$MODE" in
    personal)     do_personal ;;
    add-forgejo)  do_add_forgejo ;;
    public)       do_public ;;
esac

echo -e "\n${GREEN}Done.${NC}"
echo "Forgejo: ${FORGEJO_URL}/${FORGEJO_OWNER}/${REPO_NAME}"
