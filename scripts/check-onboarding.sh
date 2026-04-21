#!/usr/bin/env bash
# scripts/check-onboarding.sh — Acceptance test for /otherness.onboard output quality
#
# Validates that the current repo's onboarding output is structurally correct AND
# that all prerequisites for a clean first /otherness.run are present.
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
echo "[1/5] Required docs/aide/ files..."

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
echo "[2/5] docs/aide/ content structure..."

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
  JOURNEY_COUNT=$(grep -c "^## Journey [0-9]" "$DOCS_AIDE/definition-of-done.md" 2>/dev/null || echo "0")
  if [ "${JOURNEY_COUNT:-0}" -gt 0 ]; then
    echo "  OK: definition-of-done.md has $JOURNEY_COUNT journey/journeys"
  else
    echo "  ERROR: definition-of-done.md has no ## Journey sections"
    ERRORS=$((ERRORS+1))
  fi
fi

# ── Check 3: AGENTS.md required fields ──────────────────────────────────────
echo ""
echo "[3/5] AGENTS.md required fields..."

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
echo "[4/5] otherness-config.yaml required sections..."

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

# ── Check 5: First-run prerequisites (design doc 32 §Future O1) ─────────────
echo ""
echo "[5/5] First-run prerequisites..."

# 5a. report_issue must be a real integer in otherness-config.yaml (not TBD or empty)
CONFIG_FILE="$REPO_ROOT/otherness-config.yaml"
if [ -f "$CONFIG_FILE" ]; then
  REPORT_VAL=$(python3 -c "
import re
for line in open('$CONFIG_FILE'):
    m = re.match(r'\s+report_issue:\s*(\S+)', line)
    if m: print(m.group(1).strip()); break
" 2>/dev/null || echo "")
  if [[ "$REPORT_VAL" =~ ^[0-9]+$ ]] && [ "$REPORT_VAL" -gt 0 ]; then
    echo "  OK: otherness-config.yaml report_issue = $REPORT_VAL (valid integer)"
  elif [ -z "$REPORT_VAL" ] || [ "$REPORT_VAL" = "TBD" ] || [ "$REPORT_VAL" = '""' ]; then
    echo "  ERROR: otherness-config.yaml report_issue is '$REPORT_VAL' — must be a real GitHub issue number before /otherness.run"
    ERRORS=$((ERRORS+1))
  else
    echo "  WARN: otherness-config.yaml report_issue = '$REPORT_VAL' — expected a positive integer"
    WARNINGS=$((WARNINGS+1))
  fi
fi

# 5b. AGENTS.md REPORT_ISSUE must be a real integer (standalone.md reads this at startup)
AGENTS_FILE="$REPO_ROOT/AGENTS.md"
if [ -f "$AGENTS_FILE" ]; then
  AGENTS_REPORT=$(grep "^REPORT_ISSUE:" "$AGENTS_FILE" 2>/dev/null | head -1 | sed 's/^REPORT_ISSUE:\s*//' | tr -d ' ')
  if [[ "$AGENTS_REPORT" =~ ^[0-9]+$ ]] && [ "$AGENTS_REPORT" -gt 0 ]; then
    echo "  OK: AGENTS.md REPORT_ISSUE = $AGENTS_REPORT (valid integer)"
  elif [ -z "$AGENTS_REPORT" ]; then
    echo "  WARN: AGENTS.md REPORT_ISSUE missing — standalone.md will fall back to otherness-config.yaml"
    WARNINGS=$((WARNINGS+1))
  else
    echo "  ERROR: AGENTS.md REPORT_ISSUE = '$AGENTS_REPORT' — must be a real GitHub issue number"
    ERRORS=$((ERRORS+1))
  fi
fi

# 5c. autonomous_mode must be set in otherness-config.yaml
if [ -f "$CONFIG_FILE" ]; then
  AUTO_MODE=$(python3 -c "
import re
section = None
for line in open('$CONFIG_FILE'):
    s = re.match(r'^(\w[\w_]*):', line)
    if s: section = s.group(1)
    if section == 'maqa':
        m = re.match(r'\s+autonomous_mode:\s*(true|false)', line)
        if m: print(m.group(1)); break
" 2>/dev/null || echo "")
  if [ "$AUTO_MODE" = "true" ] || [ "$AUTO_MODE" = "false" ]; then
    echo "  OK: otherness-config.yaml autonomous_mode = $AUTO_MODE"
  else
    echo "  WARN: otherness-config.yaml autonomous_mode not set under [maqa] — defaults to true"
    WARNINGS=$((WARNINGS+1))
  fi
fi

# 5d. GitHub labels check — skipped gracefully if gh is not authenticated or REPO is unset
SKIP_LABEL_CHECK=false
if ! command -v gh &>/dev/null; then
  echo "  SKIP: gh CLI not available — label check skipped"
  SKIP_LABEL_CHECK=true
else
  # Infer REPO from git remote if not set as env var
  INFERRED_REPO="${REPO:-$(git -C "$REPO_ROOT" remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||;s|\.git$||')}"
  if [ -z "$INFERRED_REPO" ]; then
    echo "  SKIP: REPO not set and no git remote found — label check skipped"
    SKIP_LABEL_CHECK=true
  else
    LABEL_CHECK_OUT=$(gh label list --repo "$INFERRED_REPO" --json name --jq '[.[].name]' 2>&1)
    if echo "$LABEL_CHECK_OUT" | python3 -c "import json,sys; json.load(sys.stdin)" &>/dev/null 2>&1; then
      REQUIRED_LABELS=("otherness" "needs-human" "kind/enhancement" "kind/bug")
      for lbl in "${REQUIRED_LABELS[@]}"; do
        if echo "$LABEL_CHECK_OUT" | python3 -c "import json,sys; labels=json.load(sys.stdin); exit(0 if '$lbl' in labels else 1)" 2>/dev/null; then
          echo "  OK: label '$lbl' exists"
        else
          echo "  ERROR: label '$lbl' missing — run STEP 6b from agents/onboard.md to create labels"
          ERRORS=$((ERRORS+1))
        fi
      done
    else
      echo "  SKIP: gh not authenticated or repo not accessible — label check skipped (run: gh auth login)"
      SKIP_LABEL_CHECK=true
    fi
  fi
fi

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
if [ "$ERRORS" -eq 0 ]; then
  echo "=== onboarding check: PASSED ($WARNINGS warnings) ==="
  echo ""
  echo "Next step: run /otherness.run and confirm the first batch ships ≥1 PR with zero [NEEDS HUMAN] posts."
  exit 0
else
  echo "=== onboarding check: FAILED ($ERRORS errors, $WARNINGS warnings) ==="
  echo "  Fix the errors above before running /otherness.run."
  exit 1
fi
