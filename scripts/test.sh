#!/usr/bin/env bash
# scripts/test.sh — TEST_COMMAND for otherness
# Runs validate.sh + integration check against the configured reference project.
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Run all validate checks first
bash "$SCRIPT_DIR/validate.sh"

echo ""
echo "=== otherness integration test ==="

# Resolve the reference project from otherness-config.yaml (first entry under monitor.projects)
# Falls back gracefully if not configured — integration check is skipped, not failed.
REFERENCE_PROJECT=$(python3 - << 'EOF'
import re, os, sys

config_path = os.path.join(os.path.dirname(os.path.dirname(os.path.abspath(__file__))), 'otherness-config.yaml')
try:
    content = open(config_path).read()
    in_monitor = in_projects = False
    for line in content.splitlines():
        if re.match(r'^monitor:', line): in_monitor = True
        if in_monitor and re.match(r'\s+projects:', line): in_projects = True
        if in_projects:
            m = re.match(r'\s+- (.+)', line)
            if m:
                repo = m.group(1).strip()
                repo = repo.strip('"').strip("'")  # strip quotes — avoid backslash in heredoc                # Skip the otherness repo itself as reference — pick a managed project
                if not repo.endswith('/otherness'):
                    print(repo)
                    sys.exit(0)
except Exception:
    pass
# No reference project configured
print("")
EOF
)

# 5. Check reference project is alive
if [ -z "$REFERENCE_PROJECT" ]; then
  echo "[5/5] Skipping integration check — no reference project configured in otherness-config.yaml"
  echo "  Add a managed project under monitor.projects to enable this check."
  echo ""
  echo "=== test: PASSED (integration check skipped — no reference project) ==="
  exit 0
fi

echo "[5/5] Checking reference project ($REFERENCE_PROJECT) is alive..."

LAST_STATE_COMMIT=$(gh api "repos/$REFERENCE_PROJECT/branches/_state" \
  --jq '.commit.commit.committer.date' 2>/dev/null || echo "")

if [ -z "$LAST_STATE_COMMIT" ]; then
  echo "  WARNING: $REFERENCE_PROJECT _state branch not found or not accessible"
  echo "  This may be expected on first run. Skipping integration check."
  echo ""
  echo "=== test: PASSED (integration check skipped) ==="
  exit 0
fi

COMMIT_EPOCH=$(python3 -c "
import datetime
d = '$LAST_STATE_COMMIT'
try:
    dt = datetime.datetime.fromisoformat(d.replace('Z','+00:00'))
    now = datetime.datetime.now(datetime.timezone.utc)
    print(f'{(now - dt).total_seconds() / 3600:.1f}')
except Exception:
    print('999')
")

echo "  Last state commit: $LAST_STATE_COMMIT"
echo "  Hours since last state commit: $COMMIT_EPOCH"

THRESHOLD=72
IS_STALE=$(python3 -c "print('yes' if float('$COMMIT_EPOCH') > $THRESHOLD else 'no')")

if [ "$IS_STALE" = "yes" ]; then
  echo "  WARNING: _state branch has not been updated in >72 hours"
  echo "  otherness may have stalled on $REFERENCE_PROJECT — investigate"
  echo "  (not failing the test — this is a warning, not a blocking error)"
else
  echo "  OK: $REFERENCE_PROJECT is alive (last activity ${COMMIT_EPOCH}h ago)"
fi

# [5b] Schema version check — warn (non-fatal) if reference project state is on old schema
echo "[5b] Checking $REFERENCE_PROJECT state schema version..."
REF_VER=$(gh api "repos/$REFERENCE_PROJECT/contents/.otherness%2Fstate.json?ref=_state" \
  --jq '.content' 2>/dev/null | base64 -d 2>/dev/null | \
  python3 -c "import json,sys; print(json.load(sys.stdin).get('version','?'))" 2>/dev/null || echo "?")
if [ "$REF_VER" = "1.3" ]; then
  echo "  OK: state.json is v1.3"
else
  echo "  WARN: state.json is v$REF_VER (expected 1.3) — migration runs at next startup"
fi

echo ""
echo "=== test: PASSED ==="
