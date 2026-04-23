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
echo "[1/10] Checking for hardcoded project paths in agent files..."

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
echo "[2/10] Checking skill references..."
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
echo "[3/10] Checking required files..."
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
echo "[4/10] Checking self-update mechanism..."
if ! grep -q "git -C ~/.otherness pull" "$AGENTS_DIR/standalone.md"; then
  echo "  ERROR: standalone.md missing self-update (git pull) mechanism"
  exit 1
fi
echo "  OK: self-update present"

# 5. Check all spec.md files contain ## Design reference
ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SPECS_DIR="$ROOT_DIR/.specify/specs"
echo "[5/10] Checking spec files for ## Design reference..."
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
echo "[6/10] Checking agent files for ## MODE block..."
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

    # YAML syntax check — design doc 28 §28.1
    # Validates that SCAN 5 pressure rewrites (doc 37 §37.5) have not broken the workflow YAML.
    # Fail-open: if PyYAML is not available, skip with a warning (don't block CI).
    YAML_VALID=$(python3 -c "
import sys
try:
    import yaml
except ImportError:
    print('SKIP_NO_YAML'); sys.exit(0)
try:
    yaml.safe_load(open('$WORKFLOW_FILE').read())
    print('OK')
except yaml.YAMLError as e:
    print(f'FAIL: {e}')
" 2>/dev/null || echo "SKIP_ERR")

    case "$YAML_VALID" in
      OK)
        echo "  OK: otherness-scheduled.yml is valid YAML" ;;
      SKIP_NO_YAML|SKIP_ERR)
        echo "  WARN: could not validate YAML syntax (PyYAML unavailable or parse error reading check) — skipping" ;;
      FAIL*)

    # Bash syntax check on the run: blocks inside the workflow
    # Catches missing fi, unmatched quotes, etc. that YAML parsers miss.
    # This is what would have caught the 5-hour outage on 2026-04-22.
    BASH_VALID=$(python3 -c "
import sys, subprocess
try:
    import yaml
    wf = yaml.safe_load(open('$WORKFLOW_FILE').read())
    jobs = wf.get('jobs', {})
    errors = []
    for job_name, job in jobs.items():
        for step in job.get('steps', []):
            script = step.get('run', '')
            if not script: continue
            r = subprocess.run(['bash', '-n'], input=script,
                               capture_output=True, text=True)
            if r.returncode != 0:
                errors.append(f'step \"{step.get(\"name\",\"unnamed\")}\": {r.stderr.strip()}')
    if errors:
        print('FAIL: ' + ' | '.join(errors))
    else:
        print('OK')
except Exception as e:
    print(f'SKIP: {e}')
" 2>/dev/null || echo "SKIP_ERR")

    case "$BASH_VALID" in
      OK)
        echo "  OK: all workflow run: blocks pass bash -n syntax check" ;;
      SKIP*)
        echo "  WARN: could not run bash syntax check — skipping" ;;
      FAIL*)
        echo "  ERROR: bash syntax error in workflow run: block"
        echo "         $BASH_VALID"
        echo "         Fix before pushing — this will break all scheduled sessions."
        ERRORS=$((ERRORS+1)) ;;
    esac
        echo "  ERROR: otherness-scheduled.yml has invalid YAML syntax — likely caused by a broken SCAN 5 pressure rewrite. Restore the file or fix the indentation."
        echo "  Detail: $YAML_VALID"
        exit 1 ;;
    esac
  fi
fi

# 7. Check ⚠️ Inferred and ⚠️ Observed items have source attribution
# Each such item must end with a parenthetical attribution: (source, YYYY-MM-DD)
# Items inside fenced code blocks are excluded (they are documentation examples).
echo "[7/10] Checking ⚠️ Inferred/Observed items have source attribution..."
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

# 8. Check ✅ Present items that mention state.json fields are reflected in local state.json
# Design ref: docs/design/41-design-doc-integrity.md §41.3
# Fail-open: if .otherness/state.json absent (CI without _state), skip gracefully.
# Drift is logged as [DOC-DRIFT] warning only — not a hard error.
echo "[8/10] Checking ✅ Present items referencing state.json fields..."
python3 - <<'STATE_DRIFT_CHECK'
import re, os, json, sys

ROOT_DIR = os.getcwd()
DESIGN_DIR = os.path.join(ROOT_DIR, 'docs', 'design')
STATE_PATH = os.path.join(ROOT_DIR, '.otherness', 'state.json')

# Graceful fallback: if state.json doesn't exist locally, skip
if not os.path.exists(STATE_PATH):
    print("  OK: .otherness/state.json not present locally (CI) — skipping drift check")
    sys.exit(0)

if not os.path.isdir(DESIGN_DIR):
    print("  OK: docs/design/ not found — skipping state.json drift check")
    sys.exit(0)

try:
    state = json.load(open(STATE_PATH))
except Exception as e:
    print(f"  OK: could not read state.json ({e}) — skipping drift check")
    sys.exit(0)

# Pattern: backtick-quoted word adjacent to "state.json" in ✅ Present items
# Matches: `foo` field, write `bar` to state.json, state.json.`baz`
FIELD_PAT = re.compile(r'`([a-z_][a-zA-Z0-9_]*)` (?:field|key)|'
                        r'write `([a-z_][a-zA-Z0-9_]*)` to state\.json|'
                        r'state\.json[^`]*`([a-z_][a-zA-Z0-9_]*)`')

drifts = []

for fname in sorted(os.listdir(DESIGN_DIR)):
    if not fname.endswith('.md'):
        continue
    try:
        content = open(os.path.join(DESIGN_DIR, fname)).read()
    except Exception:
        continue

    # Only scan ✅ Present items
    for line in content.splitlines():
        if not line.startswith('- ✅'):
            continue
        if 'state.json' not in line:
            continue
        # Extract field names
        for m in FIELD_PAT.finditer(line):
            field = m.group(1) or m.group(2) or m.group(3)
            if not field:
                continue
            # Skip generic words unlikely to be state.json keys
            if field in ('the', 'a', 'an', 'true', 'false', 'null', 'none', 'str', 'int'):
                continue
            if field not in state:
                drifts.append(f"  [DOC-DRIFT] {fname}: ✅ Present mentions state.json.{field} — not found in state.json")

if drifts:
    for d in drifts:
        print(d)
    print(f"  {len(drifts)} doc-drift warning(s) — these are informational, not blocking.")
else:
    print("  OK: all ✅ Present state.json field references found in state.json")
STATE_DRIFT_CHECK

# 9. Check README last-refreshed comment when README is >90 days old
# Design ref: docs/design/39-autonomous-readme-refresh.md §Future 39.5
# Fail-open: if git is unavailable or README has no git history, skip gracefully.
# PM §5k (item 39.3) writes <!-- last-refreshed: YYYY-MM-DD --> when it refreshes the README.
echo "[9/10] Checking README last-refreshed comment..."
python3 - <<'README_CHECK'
import re, subprocess, datetime, os, sys

ROOT_DIR = os.getcwd()
readme_path = os.path.join(ROOT_DIR, 'README.md')

if not os.path.exists(readme_path):
    print("  OK: README.md not found — skipping last-refreshed check")
    sys.exit(0)

# Check for last-refreshed comment in README
try:
    content = open(readme_path).read()
except Exception:
    print("  OK: could not read README.md — skipping last-refreshed check")
    sys.exit(0)

has_comment = bool(re.search(r'<!--\s*last-refreshed:\s*\d{4}-\d{2}-\d{2}\s*-->', content))

# Get README age from git
try:
    r = subprocess.run(
        ['git', 'log', '--format=%ci', '-1', '--', 'README.md'],
        capture_output=True, text=True, timeout=10
    )
    if r.returncode != 0 or not r.stdout.strip():
        print("  OK: README.md has no git history — skipping last-refreshed check")
        sys.exit(0)
    last_modified_str = r.stdout.strip().split()[0]  # "YYYY-MM-DD"
    last_modified = datetime.date.fromisoformat(last_modified_str)
    age_days = (datetime.date.today() - last_modified).days
except Exception as e:
    print(f"  OK: could not determine README age ({e}) — skipping last-refreshed check")
    sys.exit(0)

# Only fail if README is >90 days old AND no comment exists
if age_days > 90 and not has_comment:
    print(f"  ERROR: README.md is {age_days} days old (last modified: {last_modified}) "
          f"and has no <!-- last-refreshed: YYYY-MM-DD --> comment.")
    print("  Add the comment when the README is refreshed, or run PM §5k to auto-refresh.")
    print("  Example: <!-- last-refreshed: " + datetime.date.today().isoformat() + " -->")
    sys.exit(1)
elif has_comment:
    m = re.search(r'<!--\s*last-refreshed:\s*(\d{4}-\d{2}-\d{2})\s*-->', content)
    comment_date = m.group(1) if m else "unknown"
    print(f"  OK: README last-refreshed comment found ({comment_date}, age: {age_days}d)")
else:
    print(f"  OK: README is {age_days} days old (< 90 days) — last-refreshed comment not required yet")
README_CHECK

# 10. Check cognitive-stance preambles in phase files (informational — not blocking)
# Design ref: docs/design/31-stage-2-skills-expansion.md §Future → ✅ (issue-795)
echo "[10/10] Checking cognitive-stance preambles in phase files..."
_MISSING_STANCES=0
for _phase in coord eng qa sm; do
  _phase_file="$AGENTS_DIR/phases/${_phase}.md"
  if [ -f "$_phase_file" ]; then
    if ! grep -q "Cognitive stance:" "$_phase_file" 2>/dev/null; then
      echo "  [WARN] phases/${_phase}.md: missing 'Cognitive stance:' preamble — consider adding one"
      _MISSING_STANCES=$((_MISSING_STANCES + 1))
    fi
  fi
done
if [ "$_MISSING_STANCES" -eq 0 ]; then
  echo "  OK: all phase files have cognitive-stance preambles"
fi

echo ""
echo "=== validate: PASSED ==="

# [8b/9] Python3 syntax check on python3 -c blocks in scheduled workflow
if [ -n "$SCHEDULE_CRON" ] && [ -f "$WORKFLOW_FILE" ]; then
  PYTHON_ERRORS=$(python3 -c "
import yaml, re, subprocess, sys
try:
    wf = yaml.safe_load(open('$WORKFLOW_FILE').read())
except:
    sys.exit(0)
errors = []
for job in wf.get('jobs',{}).values():
    for step in job.get('steps',[]):
        script = step.get('run','') or step.get('with',{}).get('prompt','')
        if not script: continue
        for m in re.finditer(r'python3\s+-c\s+[\"](.*?)[\"]', script, re.DOTALL):
            code = m.group(1).replace('\\\\n','\\n').replace('\\\\t','\\t')
            r = subprocess.run(['python3','-c', f'compile({repr(code)},\"<string>\",\"exec\")'],
                               capture_output=True, text=True)
            if r.returncode != 0:
                errors.append(r.stderr.strip()[:80])
if errors:
    for e in errors: print(f'FAIL: {e}')
else:
    print('OK')
" 2>/dev/null || echo "SKIP")

  case "$PYTHON_ERRORS" in
    OK)   echo "  OK: all python3 -c blocks in workflow pass syntax check" ;;
    SKIP) echo "  WARN: could not check python3 syntax — skipping" ;;
    FAIL*)
      echo "  ERROR: python3 syntax error in workflow python3 -c block"
      echo "         $PYTHON_ERRORS"
      ERRORS=$((ERRORS+1)) ;;
  esac
fi
