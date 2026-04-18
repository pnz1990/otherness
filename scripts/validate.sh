#!/usr/bin/env bash
# scripts/validate.sh — BUILD_COMMAND for otherness
# Checks structural integrity of agent files. No external dependencies.
set -e

AGENTS_DIR="$(cd "$(dirname "$0")/.." && pwd)/agents"
SKILLS_DIR="$AGENTS_DIR/skills"

echo "=== otherness validate ==="

# 1. Check no hardcoded project-specific paths in agent files.
# The rule: agent files must never reference specific projects by name — they
# run on any project and must stay generic.
#
# Detection:
#   Rule 1 — reads the project owner from otherness-config.yaml and catches any
#             <owner>/<X> that isn't <owner>/otherness. Falls back gracefully.
#   Rule 2 — reads fleet project names from otherness-config.yaml monitor.projects
#             and catches them in project-reference context.
echo "[1/5] Checking for hardcoded project paths in agent files..."

# Resolve owner from config (used in Rule 1)
OWNER=$(python3 -c "
import re, os
config = os.path.join('$(cd "$(dirname "$0")/.." && pwd)', 'otherness-config.yaml')
try:
    for line in open(config):
        m = re.match(r'^\s+repo:\s*(.+)', line)
        if m:
            parts = m.group(1).strip().strip('\"').strip(\"'\").split('/')
            if len(parts) == 2: print(parts[0]); break
except Exception:
    print('pnz1990')
" 2>/dev/null || echo "pnz1990")

# Resolve fleet project names from config (used in Rule 2)
FLEET_NAMES=$(python3 -c "
import re, os
config = os.path.join('$(cd "$(dirname "$0")/.." && pwd)', 'otherness-config.yaml')
names = []
try:
    in_monitor = in_projects = False
    for line in open(config):
        if re.match(r'^monitor:', line): in_monitor = True
        if in_monitor and re.match(r'\s+projects:', line): in_projects = True
        if in_projects:
            m = re.match(r'\s+- (.+)', line)
            if m:
                repo = m.group(1).strip().strip('\"').strip(\"'\")
                name = repo.split('/')[-1]
                if name and name != 'otherness':
                    names.append(name)
except Exception:
    pass
print(' '.join(names))
" 2>/dev/null || echo "")

FOUND=0
for file in "$AGENTS_DIR"/*.md "$AGENTS_DIR/skills"/*.md "$AGENTS_DIR/phases"/*.md; do
  [ -f "$file" ] || continue
  # PROVENANCE.md is an audit trail log — it legitimately records which project a skill
  # was extracted from. Skip it for hardcoded-path checks (see issue #78).
  if [ "$(basename $file)" = "PROVENANCE.md" ]; then
    continue
  fi
  # Rule 1: any <owner>/<X> where X is not 'otherness'
  # Exempt: HTML comment metadata lines (<!-- provenance: ... -->) in skill files.
  if grep -qE "${OWNER}/[a-zA-Z0-9_-]+" "$file" 2>/dev/null; then
    BAD=$(grep -oE "${OWNER}/[a-zA-Z0-9_-]+" "$file" \
      | grep -v "^${OWNER}/otherness$" | head -3)
    if [ -n "$BAD" ]; then
      # Re-check: filter lines that are only in HTML provenance comments
      BAD_REAL=$(grep -E "${OWNER}/[a-zA-Z0-9_-]+" "$file" \
        | grep -v "^<!--" \
        | grep -oE "${OWNER}/[a-zA-Z0-9_-]+" \
        | grep -v "^${OWNER}/otherness$" | head -3)
      if [ -n "$BAD_REAL" ]; then
        echo "  ERROR: $(basename $file) contains hardcoded project path(s): $BAD_REAL"
        FOUND=1
      fi
    fi
  fi
  # Rule 2: fleet project names in project-reference context
  for name in $FLEET_NAMES; do
    if grep -qE "(repo:|/)${name}(\.git|/|\")" "$file" 2>/dev/null; then
      echo "  ERROR: $(basename $file) contains hardcoded fleet project reference: $name"
      FOUND=1
    fi
  done
done
[ $FOUND -eq 0 ] && echo "  OK: no hardcoded project paths in agent files" || exit 1

# 2. Check all skill refs in standalone.md point to existing files
# Skill paths use ~/.otherness/agents/skills/<name>.md — on a CI runner ~/.otherness
# doesn't exist, but the files are present in the repo at agents/skills/<name>.md.
# We resolve both locations: prefer the expanded ~ path, fall back to repo-local.
echo "[2/5] Checking skill references..."
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
done < <(grep "Load skill: read" "$AGENTS_DIR/standalone.md" "$AGENTS_DIR/phases"/*.md 2>/dev/null)
[ $MISSING -eq 0 ] && echo "  OK: all skill refs resolve" || exit 1

# 3. Check required files exist
echo "[3/5] Checking required files..."
REQUIRED=(
  "$AGENTS_DIR/standalone.md"
  "$AGENTS_DIR/bounded-standalone.md"
  "$AGENTS_DIR/onboard.md"
  "$AGENTS_DIR/otherness.learn.md"
  "$AGENTS_DIR/gh-features.md"
  "$AGENTS_DIR/phases/coord.md"
  "$AGENTS_DIR/phases/eng.md"
  "$AGENTS_DIR/phases/qa.md"
  "$AGENTS_DIR/phases/sm.md"
  "$AGENTS_DIR/phases/pm.md"
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
  "$(cd "$(dirname "$0")/.." && pwd)/docs/aide/metrics.md"
  "$(cd "$(dirname "$0")/.." && pwd)/.opencode/command/otherness.run.md"
  "$(cd "$(dirname "$0")/.." && pwd)/.opencode/command/otherness.run.bounded.md"
  "$(cd "$(dirname "$0")/.." && pwd)/.opencode/command/otherness.onboard.md"
  "$(cd "$(dirname "$0")/.." && pwd)/.opencode/command/otherness.setup.md"
  "$(cd "$(dirname "$0")/.." && pwd)/.opencode/command/otherness.status.md"
  "$(cd "$(dirname "$0")/.." && pwd)/.opencode/command/otherness.upgrade.md"
  "$(cd "$(dirname "$0")/.." && pwd)/.opencode/command/otherness.learn.md"
  "$(cd "$(dirname "$0")/.." && pwd)/.opencode/command/otherness.arch-audit.md"
  "$(cd "$(dirname "$0")/.." && pwd)/.opencode/command/otherness.cross-agent-monitor.md"
  "$(cd "$(dirname "$0")/.." && pwd)/.opencode/command/otherness.vibe-vision.md"
  "$(cd "$(dirname "$0")/.." && pwd)/agents/vibe-vision.md"
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
echo "[4/5] Checking self-update mechanism..."
if ! grep -q "git -C ~/.otherness pull" "$AGENTS_DIR/standalone.md"; then
  echo "  ERROR: standalone.md missing self-update (git pull) mechanism"
  exit 1
fi
echo "  OK: self-update present"

# 5. Check all spec.md files contain ## Design reference
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SPECS_DIR="$ROOT_DIR/.specify/specs"
echo "[5/5] Checking spec files for ## Design reference..."
if [ ! -d "$SPECS_DIR" ]; then
  echo "  OK: no .specify/specs/ directory — skipping spec lint"
else
  MISSING_REF=0
  while IFS= read -r spec_file; do
    if ! grep -q "^## Design reference" "$spec_file" 2>/dev/null; then
      echo "  ERROR: spec missing ## Design reference: $spec_file"
      MISSING_REF=1
    fi
  done < <(find "$SPECS_DIR" -name "spec.md" 2>/dev/null)
  [ $MISSING_REF -eq 0 ] && echo "  OK: all spec files have ## Design reference" || exit 1
fi

echo ""
echo "=== validate: PASSED ==="
