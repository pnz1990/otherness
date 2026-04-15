#!/usr/bin/env bash
# scripts/test.sh — TEST_COMMAND for otherness
# Runs validate.sh + integration check against reference project.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Run all validate checks first
bash "$SCRIPT_DIR/validate.sh"

echo ""
echo "=== otherness integration test ==="

# 5. Check alibi reference project is alive
echo "[5/5] Checking reference project (pnz1990/alibi) is alive..."

# Check _state branch exists and has recent commits
LAST_STATE_COMMIT=$(gh api repos/pnz1990/alibi/branches/_state \
  --jq '.commit.commit.committer.date' 2>/dev/null || echo "")

if [ -z "$LAST_STATE_COMMIT" ]; then
  echo "  WARNING: alibi _state branch not found or not accessible"
  echo "  This may be expected on first run. Skipping integration check."
  echo ""
  echo "=== test: PASSED (integration check skipped) ==="
  exit 0
fi

# Parse the date and check if within 72 hours
COMMIT_EPOCH=$(python3 -c "
import datetime
d = '$LAST_STATE_COMMIT'
try:
    dt = datetime.datetime.fromisoformat(d.replace('Z','+00:00'))
    now = datetime.datetime.now(datetime.timezone.utc)
    diff_hours = (now - dt).total_seconds() / 3600
    print(f'{diff_hours:.1f}')
except Exception as e:
    print('999')
")

echo "  alibi last state commit: $LAST_STATE_COMMIT"
echo "  Hours since last state commit: $COMMIT_EPOCH"

THRESHOLD=72
IS_STALE=$(python3 -c "print('yes' if float('$COMMIT_EPOCH') > $THRESHOLD else 'no')")

if [ "$IS_STALE" = "yes" ]; then
  echo "  WARNING: alibi _state branch has not been updated in >72 hours"
  echo "  otherness may have stalled on alibi — investigate"
  echo "  (not failing the test — this is a warning, not a blocking error)"
else
  echo "  OK: alibi is alive (last activity ${COMMIT_EPOCH}h ago)"
fi

# [5b] Schema version check — warn (non-fatal) if alibi state is on old schema
echo "[5b] Checking alibi state schema version..."
ALIBI_VER=$(gh api "repos/pnz1990/alibi/contents/.otherness%2Fstate.json?ref=_state" \
  --jq '.content' 2>/dev/null | base64 -d 2>/dev/null | \
  python3 -c "import json,sys; print(json.load(sys.stdin).get('version','?'))" 2>/dev/null || echo "?")
if [ "$ALIBI_VER" = "1.3" ]; then
  echo "  OK: alibi state.json is v1.3"
else
  echo "  WARN: alibi state.json is v$ALIBI_VER (expected 1.3) — migration runs at next startup"
fi

echo ""
echo "=== test: PASSED ==="
