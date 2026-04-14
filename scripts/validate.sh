#!/usr/bin/env bash
# scripts/validate.sh — BUILD_COMMAND for otherness
# Checks structural integrity of agent files. No external dependencies.
set -e

AGENTS_DIR="$(cd "$(dirname "$0")/.." && pwd)/agents"
SKILLS_DIR="$AGENTS_DIR/skills"

echo "=== otherness validate ==="

# 1. Check no hardcoded project-specific paths in agent files
echo "[1/4] Checking for hardcoded project paths..."
FORBIDDEN_PATTERNS=("kardinal-promoter" "alibi" "pnz1990/alibi" "pnz1990/kardinal")
FOUND=0
for file in "$AGENTS_DIR"/*.md; do
  for pattern in "${FORBIDDEN_PATTERNS[@]}"; do
    if grep -q "$pattern" "$file" 2>/dev/null; then
      echo "  ERROR: $file contains hardcoded path: $pattern"
      FOUND=1
    fi
  done
done
[ $FOUND -eq 0 ] && echo "  OK: no hardcoded project paths" || exit 1

# 2. Check all skill refs in standalone.md point to existing files
# Skill paths use ~/.otherness/agents/skills/<name>.md — on a CI runner ~/.otherness
# doesn't exist, but the files are present in the repo at agents/skills/<name>.md.
# We resolve both locations: prefer the expanded ~ path, fall back to repo-local.
echo "[2/4] Checking skill references..."
MISSING=0
while IFS= read -r line; do
  # Extract path after "Load skill: read `" up to closing backtick
  skill_file=$(python3 -c "
import re, sys
m = re.search(r'read \`([^\`]+)\`', sys.stdin.read())
if m: print(m.group(1))
" <<< "$line" 2>/dev/null)
  [ -z "$skill_file" ] && continue
  expanded="${skill_file/#\~/$HOME}"
  # Also check repo-local path: ~/.otherness/agents/skills/X.md → agents/skills/X.md
  skill_basename=$(basename "$skill_file")
  repo_local="$SKILLS_DIR/$skill_basename"
  if [ ! -f "$expanded" ] && [ ! -f "$repo_local" ]; then
    echo "  ERROR: referenced skill file not found: $skill_file"
    MISSING=1
  fi
done < <(grep "Load skill: read" "$AGENTS_DIR/standalone.md" 2>/dev/null)
[ $MISSING -eq 0 ] && echo "  OK: all skill refs resolve" || exit 1

# 3. Check required files exist
echo "[3/4] Checking required files..."
REQUIRED=(
  "$AGENTS_DIR/standalone.md"
  "$AGENTS_DIR/bounded-standalone.md"
  "$AGENTS_DIR/onboard.md"
  "$AGENTS_DIR/otherness.learn.md"
  "$AGENTS_DIR/gh-features.md"
  "$SKILLS_DIR/declaring-designs.md"
  "$SKILLS_DIR/reconciling-implementations.md"
  "$SKILLS_DIR/agent-coding-discipline.md"
  "$SKILLS_DIR/autonomous-workflow-patterns.md"
  "$SKILLS_DIR/PROVENANCE.md"
  "$(cd "$(dirname "$0")/.." && pwd)/AGENTS.md"
  "$(cd "$(dirname "$0")/.." && pwd)/otherness-config.yaml"
  "$(cd "$(dirname "$0")/.." && pwd)/docs/aide/vision.md"
  "$(cd "$(dirname "$0")/.." && pwd)/docs/aide/roadmap.md"
  "$(cd "$(dirname "$0")/.." && pwd)/docs/aide/definition-of-done.md"
)
MISSING_FILES=0
for f in "${REQUIRED[@]}"; do
  if [ ! -f "$f" ]; then
    echo "  ERROR: required file missing: $f"
    MISSING_FILES=1
  fi
done
[ $MISSING_FILES -eq 0 ] && echo "  OK: all required files present" || exit 1

# 4. Check self-update is present in standalone.md
echo "[4/4] Checking self-update mechanism..."
if ! grep -q "git -C ~/.otherness pull" "$AGENTS_DIR/standalone.md"; then
  echo "  ERROR: standalone.md missing self-update (git pull) mechanism"
  exit 1
fi
echo "  OK: self-update present"

echo ""
echo "=== validate: PASSED ==="
