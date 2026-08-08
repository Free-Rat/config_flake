#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

DRY_RUN=false
if [ "${1:-}" = "--dry-run" ] || [ "${1:-}" = "-n" ]; then
    DRY_RUN=true
    echo -e "${YELLOW}[DRY RUN] no destructive actions will be taken${NC}"
fi

# ─────────────────────────────────────────────
# 1. Store health audit
# ─────────────────────────────────────────────
echo -e "${CYAN}═══ Store audit ═══${NC}"
STORE_SIZE=$(du -sh /nix/store 2>/dev/null | cut -f1)
echo -e "Store size: ${YELLOW}$STORE_SIZE${NC}"
echo ""

# ── 1a. Broken gc roots ──
echo -e "${CYAN}--- Broken GC roots ---${NC}"
BROKEN_COUNT=0
for link in /nix/var/nix/gcroots/auto/*; do
    [ -e "$link" ] || continue
    target=$(readlink "$link" 2>/dev/null || true)
    if [ ! -e "$target" ]; then
        echo -e "  ${RED}[BROKEN]${NC} $link -> $target"
        BROKEN_COUNT=$((BROKEN_COUNT + 1))
    fi
done
if [ "$BROKEN_COUNT" -eq 0 ]; then
    echo "  (none)"
fi
echo ""

# ── 1b. Old project result roots (> 60 days) ──
echo -e "${CYAN}--- Old project results (> 60 days) ---${NC}"
OLD_RESULT_COUNT=0
CUTOFF_EPOCH=$(date -d "60 days ago" +%s)
for link in /nix/var/nix/gcroots/auto/*; do
    [ -e "$link" ] || continue
    target=$(readlink "$link" 2>/dev/null || true)
    target_base=$(basename "$target" 2>/dev/null || true)
    # skip system profiles, home-manager profiles, flake registries
    case "$target" in
        /nix/var/nix/profiles/*|*flake-registry.json|*home-manager/gcroots/*) continue ;;
    esac
    if echo "$target_base" | grep -qE "^(result|result-)" 2>/dev/null; then
        mtime_epoch=$(stat -c '%Y' "$link" 2>/dev/null || echo 0)
        if [ "$mtime_epoch" -lt "$CUTOFF_EPOCH" ]; then
            age_days=$(( ($(date +%s) - mtime_epoch) / 86400 ))
            size=$(nix path-info -S "$target" 2>/dev/null | awk '{print $2}' || echo "?")
            echo -e "  ${YELLOW}[${age_days}d old]${NC} $(basename "$link") -> $target (${size})"
            OLD_RESULT_COUNT=$((OLD_RESULT_COUNT + 1))
        fi
    fi
done
if [ "$OLD_RESULT_COUNT" -eq 0 ]; then
    echo "  (none)"
fi
echo ""

# ── 1c. Old home-manager generations (> 3 kept) ──
echo -e "${CYAN}--- Home-manager gc roots (non-current) ---${NC}"
HM_COUNT=0
for link in /nix/var/nix/gcroots/auto/*; do
    [ -e "$link" ] || continue
    target=$(readlink "$link" 2>/dev/null || true)
    # match home-manager-NNN-link that are NOT the current-home root
    case "$target" in *home-manager-*-link*)
        if ! echo "$target" | grep -q "current-home"; then
            gen=$(echo "$target" | grep -oP 'home-manager-\K[0-9]+(?=-link)' || echo "?")
            size=$(nix path-info -S "$target" 2>/dev/null | awk '{print $2}' || echo "?")
            echo -e "  ${YELLOW}[gen $gen]${NC} $(basename "$link") -> $target (${size})"
            HM_COUNT=$((HM_COUNT + 1))
        fi
    esac
done
if [ "$HM_COUNT" -eq 0 ]; then
    echo "  (none)"
fi
echo ""

# ── 1d. Top large roots summary ──
echo -e "${CYAN}--- Top GC roots by closure size ---${NC}"
for link in /nix/var/nix/gcroots/auto/*; do
    [ -e "$link" ] || continue
    target=$(readlink "$link" 2>/dev/null || true)
    [ -e "$target" ] || continue
    nix path-info -S "$target" 2>/dev/null || true
done | sort -t$'\t' -k2 -hr | head -10 | while IFS=$'\t' read -r path size; do
    short=$(echo "$path" | sed 's|/nix/store/[a-z0-9]\+-||')
    echo -e "  ${size}\t$short"
done
echo ""

# ─────────────────────────────────────────────
# 2. Rebuild (ensures we're on latest config)
# ─────────────────────────────────────────────
echo -e "${GREEN}═══ Rebuilding system ═══${NC}"
if [ "$DRY_RUN" = false ]; then
    sudo nixos-rebuild switch --flake /home/freerat/config_flake
else
    echo "[DRY RUN] sudo nixos-rebuild switch --flake /home/freerat/config_flake"
fi

# ─────────────────────────────────────────────
# 3. Garbage collection
# ─────────────────────────────────────────────
echo ""
echo -e "${GREEN}═══ Garbage collection ═══${NC}"

echo "--- GC dry run (user) ---"
nix-collect-garbage --dry-run 2>&1 | grep -E "store paths|would be" || true

echo "--- GC dry run (root) ---"
sudo nix-collect-garbage --dry-run 2>&1 | grep -E "store paths|would be" || true

if [ "$DRY_RUN" = false ]; then
    echo "--- collecting user garbage ---"
    nix-collect-garbage -d
    echo "--- collecting root garbage ---"
    sudo nix-collect-garbage
    sudo nix-collect-garbage -d
    nix-collect-garbage
    nix-collect-garbage -d
else
    echo "[DRY RUN] skipping actual GC"
fi

# ─────────────────────────────────────────────
# 4. Store optimisation
# ─────────────────────────────────────────────
echo ""
echo -e "${GREEN}═══ Store optimisation ═══${NC}"

echo "--- deduplicating (nix-store --optimise) ---"
if [ "$DRY_RUN" = false ]; then
    nix-store --optimise
else
    echo "[DRY RUN] nix-store --optimise"
fi

# New-style optimise may fail on stale .drv references; try anyway
echo "--- deduplicating (nix store optimise) ---"
if [ "$DRY_RUN" = false ]; then
    nix store optimise 2>&1 || echo -e "${YELLOW}  (new-style optimise failed — already covered by nix-store --optimise)${NC}"
else
    echo "[DRY RUN] nix store optimise"
fi

# ─────────────────────────────────────────────
# 5. Final cleanup: remove broken gc roots
# ─────────────────────────────────────────────
BROKEN_REMOVED=0
for link in /nix/var/nix/gcroots/auto/*; do
    [ -e "$link" ] || continue
    target=$(readlink "$link" 2>/dev/null || true)
    if [ ! -e "$target" ]; then
        echo -e "${YELLOW}Removing broken gc root: $link${NC}"
        if [ "$DRY_RUN" = false ]; then
            sudo rm "$link"
        fi
        BROKEN_REMOVED=$((BROKEN_REMOVED + 1))
    fi
done
if [ "$BROKEN_REMOVED" -gt 0 ] && [ "$DRY_RUN" = false ]; then
    echo "  re-running root GC after broken root removal..."
    sudo nix-collect-garbage
fi

# ─────────────────────────────────────────────
# 6. Results
# ─────────────────────────────────────────────
echo ""
echo -e "${GREEN}═══ Results ═══${NC}"
du -sh /nix/store
echo ""
echo -e "${CYAN}Tips:${NC}"
echo "  Run with --dry-run / -n to audit without changes"
echo "  Stale 'result' symlinks in project dirs create GC roots; delete them when done:"
echo "    find ~/project -name result -o -name 'result-*' | head -10"
echo "  Old home-manager gc roots in /nix/var/nix/gcroots/auto/ can be removed with:"
echo "    sudo rm /nix/var/nix/gcroots/auto/<hash>"
echo "  To see all gc roots: nix-store --gc --print-roots"
