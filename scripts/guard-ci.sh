#!/bin/bash
# scripts/guard-ci.sh — Layer 3 D4 zone enforcement
# Called from CI on every PR.
# Checks that changed files match the branch's permitted zone.
# Exit 0: all checks passed. Exit 1: zone violation detected.

set -euo pipefail

BRANCH="${GITHUB_HEAD_REF:-$(git branch --show-current 2>/dev/null || echo '')}"
ERRORS=0

if [ -z "$BRANCH" ]; then
  echo "[guard-ci] No branch name detected — skipping zone enforcement."
  exit 0
fi

# Get changed files vs main
CHANGED=$(git diff --name-only origin/main...HEAD 2>/dev/null || \
          git diff --name-only HEAD~1 2>/dev/null || echo "")

if [ -z "$CHANGED" ]; then
  echo "[guard-ci] No changed files detected — skipping."
  exit 0
fi

# Files added (new) vs modified (existing)
ADDED=$(git diff --diff-filter=A --name-only origin/main...HEAD 2>/dev/null || echo "")

echo "[guard-ci] Branch: $BRANCH"
echo "[guard-ci] Changed files: $(echo "$CHANGED" | wc -l | tr -d ' ')"

case "$BRANCH" in

  feat/*)
    # IMPLEMENT zone: feat/* branches cannot CREATE new docs/aide/ or docs/design/ files.
    # They CAN modify existing design docs (🔲→✅ updates ship with features).
    # They CAN modify docs/aide/definition-of-done.md (Journey updates ship with features).
    for file in $ADDED; do
      if echo "$file" | grep -qE '^docs/aide/' || echo "$file" | grep -qE '^docs/design/'; then
        echo "[🚫 D4 GATE] feat/* branch cannot create new DOCS zone file: $file"
        echo "  Creating vision/design docs requires a vision/* branch (/otherness.vibe-vision)"
        ERRORS=$((ERRORS + 1))
      fi
    done
    if [ "$ERRORS" -eq 0 ]; then
      echo "[guard-ci] feat/* OK: no new DOCS zone files created."
    fi
    ;;

  vision/*)
    # VISION zone: vision/* branches cannot modify CODE zone files.
    # Exempt: AGENTS.md, otherness-config.yaml, .specify/d4/
    for file in $CHANGED; do
      IN_DOCS=$(echo "$file" | grep -cE '^docs/' || true)
      EXEMPT=$(echo "$file" | grep -cE '^(AGENTS\.md|otherness-config\.yaml|\.specify/d4/)' || true)
      if [ "$IN_DOCS" -eq 0 ] && [ "$EXEMPT" -eq 0 ]; then
        echo "[🚫 D4 GATE] vision/* branch cannot modify CODE zone file: $file"
        echo "  CODE zone changes require a feat/* branch (/otherness.run)"
        ERRORS=$((ERRORS + 1))
      fi
    done
    if [ "$ERRORS" -eq 0 ]; then
      echo "[guard-ci] vision/* OK: no CODE zone files modified."
    fi
    ;;

  chore/*|main)
    # Infrastructure branches and direct main pushes are exempt.
    echo "[guard-ci] $BRANCH: exempt from zone enforcement."
    ;;

  *)
    # Unrecognized branch pattern — log but do not block.
    echo "[guard-ci] Unrecognized branch pattern '$BRANCH' — skipping zone check."
    echo "           (Known patterns: feat/*, vision/*, chore/*)"
    ;;

esac

if [ "$ERRORS" -gt 0 ]; then
  echo ""
  echo "[guard-ci] D4 zone enforcement: $ERRORS violation(s) found."
  echo "           Use /otherness.run for code changes, /otherness.vibe-vision for vision/design docs."
  exit 1
fi

echo "[guard-ci] D4 zone check: passed"
exit 0
