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
echo "[1/7] Checking for hardcoded project paths in agent files..."

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
echo "[2/7] Checking skill references..."
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
echo "[3/7] Checking required files..."
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
  "$(cd "$(dirname "$0")/.." && pwd)/.opencode/command/otherness.vibe-vision.md"
  "$(cd "$(dirname "$0")/.." && pwd)/agents/vibe-vision.md"
  "$(cd "$(dirname "$0")/.." && pwd)/agents/vibe-vision-auto.md"
  "$(cd "$(dirname "$0")/.." && pwd)/agents/autonomous-vision.md"
  "$(cd "$(dirname "$0")/.." && pwd)/scripts/calibrate.py"
  "$(cd "$(dirname "$0")/.." && pwd)/scripts/sim-params.json"
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
echo "[4/7] Checking self-update mechanism..."
if ! grep -q "git -C ~/.otherness pull" "$AGENTS_DIR/standalone.md"; then
  echo "  ERROR: standalone.md missing self-update (git pull) mechanism"
  exit 1
fi
echo "  OK: self-update present"

# 5. Check all spec.md files contain ## Design reference
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SPECS_DIR="$ROOT_DIR/.specify/specs"
echo "[5/7] Checking spec files for ## Design reference..."
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

# 6. Check every agent file has a ## MODE block
echo "[6/7] Checking agent files for ## MODE block..."
MISSING_MODE=0
for agent_file in "$AGENTS_DIR"/*.md "$AGENTS_DIR/phases"/*.md; do
  [ -f "$agent_file" ] || continue
  fname=$(basename "$agent_file")
  [ "$fname" = "gh-features.md" ] && continue  # reference doc, not an agent
  if ! grep -q "^## MODE:" "$agent_file" 2>/dev/null; then
    echo "  ERROR: agent file missing ## MODE block: $agent_file"
    MISSING_MODE=1
  fi
done
[ $MISSING_MODE -eq 0 ] && echo "  OK: all agent files have ## MODE block" || exit 1

# [Optional] Check scheduled workflow exists when schedule.cron is configured
SCHEDULE_CRON=$(python3 -c "
import re
try:
    for line in open('otherness-config.yaml'):
        m = re.match(r'^\s+cron:\s*[\"\'']?([^\"\'#\n]+)[\"\'']?', line.strip())
        if m and m.group(1).strip() not in ('','\"\"',\"''\"):
            print(m.group(1).strip()); break
except: pass
" 2>/dev/null || echo "")

if [ -n "$SCHEDULE_CRON" ]; then
  WORKFLOW_FILE="$(cd "$(dirname "$0")/.." && pwd)/.github/workflows/otherness-scheduled.yml"
  if [ ! -f "$WORKFLOW_FILE" ]; then
    echo "  ERROR: schedule.cron is set ('$SCHEDULE_CRON') but .github/workflows/otherness-scheduled.yml is missing."
    echo "         Run /otherness.setup or create the workflow file. See docs/design/19-scheduled-execution.md."
    exit 1
  else
    echo "  OK: scheduled workflow present (cron: $SCHEDULE_CRON)"

    # Check dual-step workflow when vibe_vision_step is true
    # Design ref: docs/design/28-dual-step-scheduled-workflow.md
    VIBE_VISION_STEP=$(python3 -c "
import re
try:
    section = None
    for line in open('otherness-config.yaml'):
        s = re.match(r'^(\w[\w_]*):', line)
        if s: section = s.group(1)
        if section == 'schedule':
            m = re.match(r'\s+vibe_vision_step:\s*(true|false)', line)
            if m: print(m.group(1)); break
except: pass
" 2>/dev/null || echo "true")  # default: true

    if [ "${VIBE_VISION_STEP:-true}" = "true" ]; then
      # Count 'uses: anomalyco/opencode' steps in the workflow
      OPENCODE_STEP_COUNT=$(python3 -c "
import re
try:
    content = open('$WORKFLOW_FILE').read()
    # Count step blocks that use the opencode action
    steps = re.findall(r'uses:\s*anomalyco/opencode', content)
    print(len(steps))
except:
    print(0)
" 2>/dev/null || echo "0")

      if [ "${OPENCODE_STEP_COUNT:-0}" -lt 2 ]; then
        echo "  ERROR: schedule.vibe_vision_step=true but $WORKFLOW_FILE has only ${OPENCODE_STEP_COUNT} opencode step(s) (need ≥2)."
        echo "         Add Step A (vibe-vision) before Step B (run). See docs/design/28-dual-step-scheduled-workflow.md."
        exit 1
      else
        echo "  OK: scheduled workflow has ${OPENCODE_STEP_COUNT} opencode steps (dual-step: vision + run)"
      fi
    fi
  fi
fi

# 7. Check ⚠️ Inferred and ⚠️ Observed items have source attribution
# Each such item must end with a parenthetical attribution: (source, YYYY-MM-DD)
# Items inside fenced code blocks are excluded (they are documentation examples).
echo "[7/7] Checking ⚠️ Inferred/Observed items have source attribution..."
python3 - <<'INFERRED_CHECK'
import re, os, sys

DESIGN_DIR = os.path.join(os.getcwd(), 'docs', 'design')
DESIGN_DIR = os.path.normpath(DESIGN_DIR)

# Attribution pattern: ends with (anything, YYYY-MM-DD) or (anything, YYYY-MM-DD).
ATTRIBUTION_RE = re.compile(r'\([^()]+,\s*\d{4}-\d{2}-\d{2}\)\.?\s*$')

errors = []

if not os.path.isdir(DESIGN_DIR):
    print("  OK: docs/design/ not found — skipping ⚠️ attribution check")
    sys.exit(0)

for fname in sorted(os.listdir(DESIGN_DIR)):
    if not fname.endswith('.md'):
        continue
    filepath = os.path.join(DESIGN_DIR, fname)
    try:
        content = open(filepath).read()
    except Exception:
        continue

    # Remove fenced code blocks to avoid false positives in examples
    content_no_code = re.sub(r'```.*?```', '', content, flags=re.DOTALL)

    for lineno, line in enumerate(content_no_code.splitlines(), 1):
        # Check for ⚠️ Inferred or ⚠️ Observed items
        if not re.search(r'^- 🔲 ⚠️ (Inferred|Observed):', line):
            continue
        # Must have source attribution
        if not ATTRIBUTION_RE.search(line):
            errors.append(f"  ERROR: {fname}: ⚠️ Inferred/Observed item missing attribution: {line.strip()[:80]}")

if errors:
    for e in errors:
        print(e)
    print(f"  {len(errors)} item(s) missing source attribution.")
    print("  Format required: (source, YYYY-MM-DD) at end of item")
    sys.exit(1)
else:
    print("  OK: all ⚠️ Inferred/Observed items have source attribution")
INFERRED_CHECK

echo ""
echo "=== validate: PASSED ==="
