---
name: vibe-vision-auto
description: "Autonomous vision scan agent for scheduled execution. Runs non-interactively: promotes shipped Future items to Present, flags stale Present items, adds inferred Future items from code gaps. Never waits for human input. Used as Step A in the dual-step scheduled workflow."
tools: Bash, Read, Write, Edit, Glob, Grep
---

## MODE: VISION

This agent may write to the DOCS zone only.
DOCS zone: `docs/aide/`, `docs/design/`, `docs/*.md`.

This agent does NOT write specs, code, scripts, or any file outside `docs/`.
This agent stops after D4 artifacts are committed. It does not claim issues,
open feat/* branches, write specs, or merge implementation PRs.

If asked to implement: stop and redirect.

```
[🚫 D4 GATE] Blocked. Code changes require /otherness.run.
This session (vibe-vision-auto) writes vision artifacts only.
```

> **Running autonomously** — no human input expected. Scan, update, commit. Then exit.

---

## SELF-UPDATE

```bash
export GIT_TERMINAL_PROMPT=0
git -C ~/.otherness pull --quiet 2>/dev/null || true
echo "[VIBE-VISION-AUTO] Agent files up to date."
```

---

## STARTUP

```bash
git config pull.rebase false 2>/dev/null || true
git fetch --prune --quiet 2>/dev/null || true
git pull origin main --quiet 2>/dev/null || true

REPO=$(git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||;s|\.git$||')
REPORT_ISSUE=$(python3 -c "
import re
for line in open('otherness-config.yaml'):
    m = re.match(r'^\s+report_issue:\s*(\S+)', line)
    if m: print(m.group(1)); break
" 2>/dev/null || echo "1")
PR_LABEL=$(python3 -c "
import re
for line in open('otherness-config.yaml'):
    m = re.match(r'^\s+pr_label:\s*[\"\'']?([^\"\'#\n]+)[\"\'']?', line)
    if m: print(m.group(1).strip()); break
" 2>/dev/null || echo "otherness")

# Check if vibe_vision_step is enabled (default: true)
VIBE_ENABLED=$(python3 -c "
import re
section = None
for line in open('otherness-config.yaml'):
    s = re.match(r'^(\w[\w_]*):', line)
    if s: section = s.group(1)
    if section == 'schedule':
        m = re.match(r'\s+vibe_vision_step:\s*(true|false)', line)
        if m: print(m.group(1)); break
" 2>/dev/null || echo "true")

if [ "$VIBE_ENABLED" = "false" ]; then
  echo "[VIBE-VISION-AUTO] vibe_vision_step=false in config — skipping."
  exit 0
fi

export REPO REPORT_ISSUE PR_LABEL
echo "[VIBE-VISION-AUTO] Starting autonomous vision scan. Repo: $REPO"
```

---

## SCAN 1 — Promote shipped Future items to Present

For each `docs/design/*.md` file: find `🔲 Future` items that have already been
implemented (evidence: merged PR, recent commit touching the related code, or
referenced function/file exists and is tested).

```bash
python3 - <<'PROMOTE_EOF'
import re, os, subprocess

design_dir = 'docs/design'
changes = []

if not os.path.isdir(design_dir):
    print("[SCAN 1] No docs/design/ directory — skipping.")
    exit(0)

for fname in sorted(os.listdir(design_dir)):
    if not fname.endswith('.md'): continue
    fpath = f'{design_dir}/{fname}'
    try:
        content = open(fpath).read()
    except:
        continue

    # Find Future section items
    future_match = re.search(r'^## Future.*?\n(.*?)(?=^## |\Z)', content, re.MULTILINE | re.DOTALL)
    if not future_match:
        continue
    future_text = future_match.group(1)
    future_items = re.findall(r'^(- 🔲 (?!.*🚫)(.+))', future_text, re.MULTILINE)

    for full_line, item_text in future_items:
        # Check if there's a corresponding merged PR (look for the item text in recent merged PRs)
        # Heuristic: if the item text (first 40 chars) appears in a merged PR title in last 60 days
        search_term = item_text[:40].strip()
        try:
            result = subprocess.run(
                ['gh', 'pr', 'list', '--repo', os.environ.get('REPO',''),
                 '--state', 'merged', '--limit', '50',
                 '--json', 'title,mergedAt,number',
                 '--jq', f'[.[] | select(.title | test("{re.escape(search_term[:20])}";"i"))] | .[0]'],
                capture_output=True, text=True, timeout=15)
            if result.returncode == 0 and result.stdout.strip() and result.stdout.strip() != 'null':
                import json
                pr_data = json.loads(result.stdout.strip())
                if pr_data:
                    pr_num = pr_data.get('number', '?')
                    pr_title = pr_data.get('title', '')
                    # Replace 🔲 with ✅ and add PR reference
                    new_line = full_line.replace('🔲', '✅') + f' (PR #{pr_num})'
                    # Only mark as present if line still has 🔲 (not already promoted)
                    if '🔲' in full_line:
                        content = content.replace(full_line, new_line, 1)
                        changes.append(f'{fname}: promoted "{item_text[:50]}" → ✅ (PR #{pr_num})')
                        print(f'[SCAN 1] {fname}: promoting "{item_text[:50]}" → ✅ (PR #{pr_num})')
        except Exception as e:
            pass  # non-fatal

    if changes:
        with open(fpath, 'w') as f:
            f.write(content)

if not changes:
    print('[SCAN 1] No shippable Future items found to promote.')
else:
    print(f'[SCAN 1] Promoted {len(changes)} item(s):')
    for c in changes:
        print(f'  {c}')
PROMOTE_EOF
```

---

## SCAN 2 — Flag stale Present items

For each `✅ Present` item that references a specific file or function: verify it
still exists. If not, mark it `⚠️ Stale`.

```bash
python3 - <<'STALE_EOF'
import re, os

design_dir = 'docs/design'
stale_count = 0

if not os.path.isdir(design_dir):
    print("[SCAN 2] No docs/design/ directory — skipping.")
    exit(0)

for fname in sorted(os.listdir(design_dir)):
    if not fname.endswith('.md'): continue
    fpath = f'{design_dir}/{fname}'
    try:
        content = open(fpath).read()
    except:
        continue

    present_match = re.search(r'^## Present.*?\n(.*?)(?=^## |\Z)', content, re.MULTILINE | re.DOTALL)
    if not present_match:
        continue

    present_text = present_match.group(1)
    present_items = re.findall(r'^(- ✅ .+)', present_text, re.MULTILINE)
    modified = False

    for item in present_items:
        # Look for file path references like scripts/foo.sh, agents/phases/bar.md
        # Only accept refs with recognized file extensions — excludes hostnames like
        # token.actions.githubusercontent.com (ext=com, not a file extension).
        _FILE_EXTS = {'md','sh','yml','yaml','json','py','go','ts','js','tsx','jsx',
                      'txt','toml','lock','env','template','html','css','rs','kt','java'}
        file_refs = [r for r in re.findall(r'`([a-zA-Z0-9_./-]+\.[a-zA-Z]{1,6})`', item)
                     if r.rsplit('.',1)[-1].lower() in _FILE_EXTS]
        for fref in file_refs:
            # Determine if the file reference exists in the repository.
            # Strategy:
            #   1. Try the exact path as written (handles .github/workflows/, .opencode/command/).
            #   2. If the ref has no path separator (bare filename), search recursively by basename.
            #   3. If the ref has a path separator, require the full path to exist — no fuzzy match.
            # This avoids false positives when a bare name like 'otherness-scheduled.yml' is used
            # while also correctly requiring 'scripts/vision.md' to exist at that exact path.
            def _file_exists(ref):
                # Exact path match (also handles refs with leading dot like .github/workflows/)
                if os.path.exists(ref) or os.path.exists(f'./{ref}'):
                    return True
                # Strip leading ./ if present
                if ref.startswith('./') and os.path.exists(ref[2:]):
                    return True
                # If ref contains a path separator: require exact location — no fuzzy match
                name_part = ref.lstrip('./')
                if '/' in name_part:
                    return False
                # Bare filename (no path): search recursively by basename
                for root, dirs, files in os.walk('.'):
                    dirs[:] = [d for d in dirs if d != '.git']
                    if name_part in files:
                        return True
                return False
            if not _file_exists(fref):
                if '⚠️ Stale' not in item:
                    new_item = item + ' ⚠️ Stale — referenced file not found'
                    content = content.replace(item, new_item, 1)
                    modified = True
                    stale_count += 1
                    print(f'[SCAN 2] {fname}: stale ref — {fref} not found in "{item[:60]}"')
                break  # one stale flag per item

    if modified:
        with open(fpath, 'w') as f:
            f.write(content)

if stale_count == 0:
    print('[SCAN 2] No stale Present items found.')
else:
    print(f'[SCAN 2] Flagged {stale_count} stale item(s).')
STALE_EOF
```

---

## SCAN 3 — Add inferred Future items from code-doc gaps

Compare the codebase's key capability areas against what's in `docs/design/`.
If a significant code area has no corresponding design doc Future items, add them.
Cap at 5 new items per scan to avoid queue flooding.

```bash
python3 - <<'INFER_EOF'
import re, os, subprocess, json

design_dir = 'docs/design'
max_new_items = 5
added = 0

if not os.path.isdir(design_dir):
    print("[SCAN 3] No docs/design/ directory — skipping.")
    exit(0)

# Collect all existing Future items (to avoid duplicates)
existing_future = set()
for fname in os.listdir(design_dir):
    if not fname.endswith('.md'): continue
    try:
        content = open(f'{design_dir}/{fname}').read()
        items = re.findall(r'^- 🔲 (.+)', content, re.MULTILINE)
        for item in items:
            existing_future.add(item.lower()[:60])
    except: pass

# Look for TODO/FIXME/HACK comments in code — these are unfulfilled design intent
result = subprocess.run(
    ['git', 'grep', '-rn', '--no-color',
     '-e', 'TODO:', '-e', 'FIXME:', '-e', 'HACK:',
     '--', '*.py', '*.go', '*.ts', '*.tsx', '*.js', '*.sh'],
    capture_output=True, text=True, timeout=30)

code_todos = []
for line in result.stdout.splitlines()[:30]:  # limit to 30
    m = re.match(r'^([^:]+):(\d+):.*(TODO|FIXME|HACK)[:\s]+(.+)$', line)
    if m:
        fpath, lineno, kind, msg = m.groups()
        msg_clean = msg.strip()[:80]
        if msg_clean.lower()[:60] not in existing_future and len(msg_clean) > 10:
            code_todos.append((fpath, lineno, kind, msg_clean))

if not code_todos:
    print('[SCAN 3] No untracked TODOs/FIXMEs found.')
    exit(0)

# Group by file area and add to the most relevant design doc
# Heuristic: match file path against design doc filename/content
print(f'[SCAN 3] Found {len(code_todos)} untracked code intent markers.')

# Add to a catch-all hygiene doc or the most recently modified design doc
# Find the most relevant doc by keyword matching
for fpath, lineno, kind, msg in code_todos[:max_new_items]:
    if added >= max_new_items:
        break

    # Skip if too vague
    if len(msg) < 15:
        continue

    # Find best matching design doc
    best_doc = None
    best_score = 0
    area_keywords = re.findall(r'\b[a-z]{4,}\b', msg.lower())
    for dfname in os.listdir(design_dir):
        if not dfname.endswith('.md'): continue
        score = sum(1 for kw in area_keywords if kw in dfname.lower())
        if score > best_score:
            best_score = score
            best_doc = dfname

    # Fallback: use the last design doc (highest number)
    if not best_doc:
        docs_numbered = sorted([f for f in os.listdir(design_dir) if re.match(r'^\d+', f)])
        if docs_numbered:
            best_doc = docs_numbered[-1]

    if not best_doc:
        continue

    dfpath = f'{design_dir}/{best_doc}'
    try:
        content = open(dfpath).read()
        # Avoid duplicates
        if msg.lower()[:40] in content.lower():
            continue

        new_item = f'- 🔲 {msg} — ⚠️ Inferred from `{fpath}:{lineno}` ({kind})'

        # Insert into Future section
        future_match = re.search(r'^(## Future.*?\n)', content, re.MULTILINE)
        if future_match:
            insert_pos = future_match.end()
            content = content[:insert_pos] + new_item + '\n' + content[insert_pos:]
            with open(dfpath, 'w') as f:
                f.write(content)
            added += 1
            print(f'[SCAN 3] Added to {best_doc}: {msg[:60]}')
    except Exception as e:
        print(f'[SCAN 3] Error updating {best_doc}: {e}')

print(f'[SCAN 3] Added {added} inferred Future item(s).')
INFER_EOF
```

---

## SCAN 4 — Deprecate old stale Future items (90+ days, no issue)

`🔲 Future` items that have existed for >90 days with no corresponding open issue
are candidates for demotion. Mark them `🔲 Future [stale — no issue, 90d+]` to
signal they need human review before re-queuing.

```bash
python3 - <<'DEPRECATE_EOF'
import re, os, subprocess, datetime

design_dir = 'docs/design'
now = datetime.datetime.utcnow()
deprecated = 0

if not os.path.isdir(design_dir):
    exit(0)

REPO = os.environ.get('REPO', '')

# Get all open issue titles for comparison
try:
    open_issues = subprocess.check_output(
        ['gh', 'issue', 'list', '--repo', REPO, '--state', 'open',
         '--limit', '200', '--json', 'title', '--jq', '.[].title'],
        text=True, timeout=20).strip().lower()
except:
    open_issues = ''

for fname in sorted(os.listdir(design_dir)):
    if not fname.endswith('.md'): continue
    fpath = f'{design_dir}/{fname}'
    try:
        content = open(fpath).read()
    except:
        continue

    items = re.findall(r'^(- 🔲 (?!.*\[stale)(?!.*🚫)(.+))', content, re.MULTILINE)
    modified = False

    for full_line, item_text in items:
        # Skip already-flagged items
        if '[stale' in full_line or 'superseded' in full_line.lower():
            continue
        # Check when this line was added via git log
        try:
            blame = subprocess.run(
                ['git', 'log', '--follow', '--diff-filter=A', '--format=%ci',
                 '--', fpath],
                capture_output=True, text=True, timeout=10)
            # Use file creation date as proxy (conservative: don't flag recent docs)
            dates = re.findall(r'(\d{4}-\d{2}-\d{2})', blame.stdout)
            if dates:
                oldest = datetime.datetime.fromisoformat(dates[-1])
                age = (now - oldest).days
            else:
                age = 0
        except:
            age = 0

        if age < 90:
            continue

        # Check if there's an open issue
        item_key = item_text[:30].lower().strip()
        has_issue = item_key in open_issues

        if not has_issue and age >= 90:
            new_line = full_line.replace('🔲', '🔲') + f' [stale — {age}d, no issue]'
            content = content.replace(full_line, new_line, 1)
            modified = True
            deprecated += 1
            print(f'[SCAN 4] {fname}: deprecated "{item_text[:50]}" ({age}d old, no issue)')

    if modified:
        with open(fpath, 'w') as f:
            f.write(content)

print(f'[SCAN 4] Deprecated {deprecated} stale Future item(s).')
DEPRECATE_EOF
```

---

## COMMIT

If any files changed, commit to the session branch (Step B will see the changes
immediately; SM §4g will merge the session branch at end of batch).

```bash
# Check for doc changes
git diff --quiet docs/ 2>/dev/null
DOCS_DIRTY=$?

if [ $DOCS_DIRTY -ne 0 ]; then
  git add docs/ 2>/dev/null || true
  SUMMARY=$(git diff --cached --stat 2>/dev/null | tail -1 || echo "doc updates")
  git commit -m "vision(auto): autonomous scan — promote shipped items, flag stale, infer gaps

Vibe-vision autonomous scan (Step A). No human input required.
Changes: $SUMMARY

Scans performed:
- Scan 1: promote shipped 🔲 Future → ✅ Present (matched against merged PRs)
- Scan 2: flag stale ✅ Present items (referenced files missing)
- Scan 3: infer 🔲 Future items from untracked TODO/FIXME in code
- Scan 4: deprecate 🔲 Future items stale >90 days with no open issue" 2>/dev/null || true

  echo "[VIBE-VISION-AUTO] Vision scan committed. Step B will see updated docs."

  # Post to report issue
  gh issue comment $REPORT_ISSUE --repo $REPO \
    --body "[🌀 VIBE-VISION-AUTO] Autonomous vision scan complete.
$SUMMARY
Step B (run) will pick up any updated queue items." 2>/dev/null || true
else
  echo "[VIBE-VISION-AUTO] No doc changes — design docs are current."
fi

echo "[VIBE-VISION-AUTO] Step A complete. Exiting for Step B."
```

---

## HARD RULES

- **Never wait for human input.** This is a fully autonomous agent.
- **Never write code.** Docs zone only.
- **Never open GitHub issues directly.** Future items in design docs → COORD creates issues.
- **Cap Scan 3 inferred items at 5 per run.** No queue flooding.
- **Never modify `AGENTS.md`.** It is protected.
- **Commit to session branch, not main directly.** SM §4g merges at batch end.
- **Always exit cleanly.** Step B depends on this step completing (even with 0 changes).
