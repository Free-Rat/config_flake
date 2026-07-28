#!/bin/sh
set -eu

AUTOUPDATE=false
NVD_DIFF_ENABLED=false
HOST="maliketh"

for arg do
  case "$arg" in
    --autoupdate|-u) AUTOUPDATE=true ;;
    --nvd-diff|-n) NVD_DIFF_ENABLED=true ;;
    -*) echo "Unknown option: $arg" >&2; exit 2 ;;
    *) HOST="$arg" ;;
  esac
done

DATE=$(date -u +%Y-%m-%dT%H:%M:%SZ)
NIX="@nix@"
GRYPE="@grype@"
GRYPE_CONFIG="@grypeConfig@"
NVD="@nvd@"
JQ="@jq@"

log() { echo "[vulnscan] $*" >&2; }

die() { log "FATAL: $*"; exit 2; }

do_scan() {
  local LABEL="$1"
  local SBOM GRYPE_JSON TOPLEVEL NVD_DIFF

  log "Building SBOM for $HOST... (may take a while after nix flake update)"
  SBOM=$("$NIX" build --no-link --print-out-paths ".#sbom-$HOST" 2>/dev/null) || {
    printf '{"label":"%s","error":"sbom build failed"}\n' "$LABEL"
    return 2
  }

  log "Running grype (only-fixed)..."
  GRYPE_JSON=$("$GRYPE" "sbom:$SBOM" --config "$GRYPE_CONFIG" --only-fixed -o json 2>/dev/null) || {
    printf '{"label":"%s","error":"grype scan failed"}\n' "$LABEL"
    return 2
  }

  local TOTAL CRITICAL HIGH MEDIUM CVE_LIST
  TOTAL=$(echo "$GRYPE_JSON" | "$JQ" -r '.matches | length')
  CRITICAL=$(echo "$GRYPE_JSON" | "$JQ" -r \
    '[.matches[] | select(.vulnerability.severity == "Critical")] | length')
  HIGH=$(echo "$GRYPE_JSON" | "$JQ" -r \
    '[.matches[] | select(.vulnerability.severity == "High")] | length')
  MEDIUM=$(echo "$GRYPE_JSON" | "$JQ" -r \
    '[.matches[] | select(.vulnerability.severity == "Medium")] | length')
  CVE_LIST=$(echo "$GRYPE_JSON" | "$JQ" -r \
    '[.matches[] | {id: .vulnerability.id, severity: .vulnerability.severity, pkg: .artifact.name, version: .artifact.version, fixed: .vulnerability.fix.version}]')

  NVD_DIFF=""
  if [ "$NVD_DIFF_ENABLED" = true ]; then
    log "Building toplevel for $HOST..."
    TOPLEVEL=$("$NIX" build --no-link --print-out-paths ".#toplevel-$HOST" 2>/dev/null) || true
    if [ -n "$TOPLEVEL" ] && [ -e /run/current-system ]; then
      log "Running nvd diff..."
      NVD_DIFF=$("$NVD" diff /run/current-system "$TOPLEVEL" 2>/dev/null || echo "")
    fi
  fi

  "$JQ" -n \
    --arg label "$LABEL" \
    --argjson total "$TOTAL" \
    --argjson critical "$CRITICAL" \
    --argjson high "$HIGH" \
    --argjson medium "$MEDIUM" \
    --argjson cves "$CVE_LIST" \
    --arg nvd_diff "$NVD_DIFF" \
    '{
      label: $label,
      vulnerabilities: { total: $total, critical: $critical, high: $high, medium: $medium },
      cves: $cves,
      nvd_diff: $nvd_diff
    }'
}

# --- Initial scan ---
SCAN_OUT=$(do_scan "before") || {
  log "Scan failed. Output:"
  echo "$SCAN_OUT"
  exit 2
}

if echo "$SCAN_OUT" | "$JQ" -e '.error' >/dev/null 2>&1; then
  log "Scan returned error: $(echo "$SCAN_OUT" | "$JQ" -r '.error')"
  exit 2
fi
BEFORE="$SCAN_OUT"

AFTER="null"
UPDATED=false
BEFORE_TOTAL=$(echo "$BEFORE" | "$JQ" -r '.vulnerabilities.total')
BEFORE_CRITICAL=$(echo "$BEFORE" | "$JQ" -r '.vulnerabilities.critical')

if [ "$AUTOUPDATE" = true ] && [ "$BEFORE_TOTAL" -gt 0 ]; then
  log "Found $BEFORE_TOTAL vulnerabilities. Running nix flake update..."
  "$NIX" flake update 2>&1 >&2 || log "ERROR: nix flake update failed"
  UPDATED=true

  SCAN_OUT=$(do_scan "after") || {
    log "Post-update scan failed. Output:"
    echo "$SCAN_OUT"
    exit 2
  }
  if echo "$SCAN_OUT" | "$JQ" -e '.error' >/dev/null 2>&1; then
    log "Post-update scan returned error: $(echo "$SCAN_OUT" | "$JQ" -r '.error')"
    exit 2
  fi
  AFTER="$SCAN_OUT"

  AFTER_TOTAL=$(echo "$AFTER" | "$JQ" -r '.vulnerabilities.total')
  AFTER_CRITICAL=$(echo "$AFTER" | "$JQ" -r '.vulnerabilities.critical')

  DELTA=$((BEFORE_TOTAL - AFTER_TOTAL))
  if [ "$DELTA" -gt 0 ]; then
    log "Fixed by update: $DELTA CVEs."
  elif [ "$DELTA" -lt 0 ]; then
    log "WARNING: $(( -DELTA )) new CVEs appeared after update."
  else
    log "No change after update ($BEFORE_TOTAL CVEs remain)."
  fi
elif [ "$AUTOUPDATE" = true ]; then
  log "No vulnerabilities found. Skipping update."
fi

# --- Output combined report ---
FINAL_CRITICAL="${AFTER_CRITICAL:-$BEFORE_CRITICAL}"

"$JQ" -n \
  --arg host "$HOST" \
  --arg timestamp "$DATE" \
  --argjson before "$BEFORE" \
  --argjson after "$AFTER" \
  --argjson updated "$UPDATED" \
  '{
    host: $host,
    timestamp: $timestamp,
    before: $before,
    after: $after,
    updated: $updated
  }'

if [ "${FINAL_CRITICAL:-0}" -gt 0 ]; then
  log "CRITICAL: $FINAL_CRITICAL fixed vulnerabilities remain. Manual investigation needed."
  exit 1
fi
log "OK: no critical fixed vulnerabilities."
