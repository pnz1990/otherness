#!/usr/bin/env bash
# scripts/check-onboarding.sh — Acceptance test for /otherness.onboard output quality
#
# Validates that the current repo's onboarding output is structurally correct.
# A repo passes if /otherness.run can start without manual edits to docs/aide/.
#
# Usage:
#   bash scripts/check-onboarding.sh          — check current working directory
#   bash scripts/check-onboarding.sh /path    — check specific directory
#
# Exit 0: all checks pass
# Exit 1: one or more required items missing or malformed (details printed)

set -euo pipefail

REPO_ROOT="${1:-$(pwd)}"
ERRORS=0
WARNINGS=0

echo "=== otherness onboarding quality check ==="
echo "Checking: $REPO_ROOT"
echo ""

# ── Check 1: Required docs/aide/ files ──────────────────────────────────────
echo "[1/4] Required docs/aide/ files..."

DOCS_AIDE="$REPO_ROOT/docs/aide"
REQUIRED_DOCS=("vision.md" "roadmap.md" "definition-of-done.md")
for doc in "${REQUIRED_DOCS[@]}"; do
  path="$DOCS_AIDE/$doc"
  if [ ! -f "$path" ]; then
    echo "  ERROR: docs/aide/$doc missing"
    ERRORS=$((ERRORS+1))
  elif [ ! -s "$path" ]; then
    echo "  ERROR: docs/aide/$doc is empty"
    ERRORS=$((ERRORS+1))
  else
    echo "  OK: docs/aide/$doc present ($(wc -l < "$path") lines)"
  fi
done

OPTIONAL_DOCS=("progress.md" "metrics.md")
for doc in "${OPTIONAL_DOCS[@]}"; do
  path="$DOCS_AIDE/$doc"
  if [ ! -f "$path" ]; then
    echo "  WARN: docs/aide/$doc optional file missing (not required)"
    WARNINGS=$((WARNINGS+1))
  fi
done

# ── Check 2: docs/aide/ content structure ───────────────────────────────────
echo ""
echo "[2/4] docs/aide/ content structure..."

# vision.md: must have a vision/what-is section
if [ -f "$DOCS_AIDE/vision.md" ] && [ -s "$DOCS_AIDE/vision.md" ]; then
  if grep -qiE "^## (what is|vision|about|overview|goal|purpose|the goal|what .* is)" "$DOCS_AIDE/vision.md"; then
    echo "  OK: vision.md has vision section"
  else
    echo "  WARN: vision.md missing expected vision section header (## Vision, ## What is, ## The goal, etc.)"
    WARNINGS=$((WARNINGS+1))
  fi
fi

# roadmap.md: must have at least one ## Stage
if [ -f "$DOCS_AIDE/roadmap.md" ] && [ -s "$DOCS_AIDE/roadmap.md" ]; then
  STAGE_COUNT=$(grep -c "^## Stage" "$DOCS_AIDE/roadmap.md" 2>/dev/null || echo "0")
  if [ "${STAGE_COUNT:-0}" -gt 0 ]; then
    echo "  OK: roadmap.md has $STAGE_COUNT stage(s)"
  else
    echo "  ERROR: roadmap.md has no ## Stage sections"
    ERRORS=$((ERRORS+1))
  fi
fi

# definition-of-done.md: must have at least one ## Journey
if [ -f "$DOCS_AIDE/definition-of-done.md" ] && [ -s "$DOCS_AIDE/definition-of-done.md" ]; then
  JOURNEY_COUNT=$(grep -c "^## Journey" "$DOCS_AIDE/definition-of-done.md" 2>/dev/null || echo "0")
  if [ "${JOURNEY_COUNT:-0}" -gt 0 ]; then
    echo "  OK: definition-of-done.md has $JOURNEY_COUNT journey/journeys"
  else
    echo "  ERROR: definition-of-done.md has no ## Journey sections"
    ERRORS=$((ERRORS+1))
  fi
fi

# ── Check 3: AGENTS.md required fields ──────────────────────────────────────
echo ""
echo "[3/4] AGENTS.md required fields..."

AGENTS_FILE="$REPO_ROOT/AGENTS.md"
if [ ! -f "$AGENTS_FILE" ]; then
  echo "  ERROR: AGENTS.md missing"
  ERRORS=$((ERRORS+1))
else
  REQUIRED_FIELDS=("PROJECT_NAME" "BUILD_COMMAND" "TEST_COMMAND" "REPORT_ISSUE" "PR_LABEL")
  for field in "${REQUIRED_FIELDS[@]}"; do
    if grep -q "^${field}:" "$AGENTS_FILE"; then
      VALUE=$(grep "^${field}:" "$AGENTS_FILE" | head -1 | sed "s/^${field}:\s*//")
      if [ -z "$VALUE" ]; then
        echo "  WARN: AGENTS.md $field is empty"
        WARNINGS=$((WARNINGS+1))
      else
        echo "  OK: AGENTS.md $field = $VALUE"
      fi
    else
      echo "  ERROR: AGENTS.md missing required field: $field"
      ERRORS=$((ERRORS+1))
    fi
  done
fi

# ── Check 4: otherness-config.yaml required sections ────────────────────────
echo ""
echo "[4/4] otherness-config.yaml required sections..."

CONFIG_FILE="$REPO_ROOT/otherness-config.yaml"
if [ ! -f "$CONFIG_FILE" ]; then
  echo "  ERROR: otherness-config.yaml missing"
  ERRORS=$((ERRORS+1))
else
  REQUIRED_SECTIONS=("project" "schedule")
  for section in "${REQUIRED_SECTIONS[@]}"; do
    if grep -q "^${section}:" "$CONFIG_FILE"; then
      echo "  OK: otherness-config.yaml has section: $section"
    else
      echo "  WARN: otherness-config.yaml missing section: $section (using defaults)"
      WARNINGS=$((WARNINGS+1))
    fi
  done
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "=== onboarding check: PASSED ($WARNINGS warnings) ==="
  exit 0
else
  echo "=== onboarding check: FAILED ($ERRORS errors, $WARNINGS warnings) ==="
  echo "  Fix the errors above before running /otherness.run."
  exit 1
fi
