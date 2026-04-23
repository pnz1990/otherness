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
import re, os, subprocess, json, datetime

design_dir = 'docs/design'
max_new_items = 5
added = 0

REPO = os.environ.get('REPO', '')

if not os.path.isdir(design_dir):
    print("[SCAN 3] No docs/design/ directory — skipping.")
    exit(0)

# §42.1 — Pre-scan: check age of existing ⚠️ Inferred items with (date: YYYY-MM-DD).
# Items older than 30 days with no open GitHub issue → create a re-issue.
# Cap: 3 re-issues per scan run. Graceful fallback on API errors.
MAX_REISSUES = 3
reissues_created = 0
today = datetime.date.today()
DATE_PATTERN = re.compile(r'⚠️ Inferred from.*?\(date:\s*(\d{4}-\d{2}-\d{2})\)')

print('[SCAN 3] §42.1: checking age of existing ⚠️ Inferred items with date annotations...')

for fname in sorted(os.listdir(design_dir)):
    if not fname.endswith('.md') or reissues_created >= MAX_REISSUES:
        break
    try:
        content = open(os.path.join(design_dir, fname)).read()
        # Find all 🔲 ⚠️ Inferred items that have a (date: ...) annotation
        for line in content.splitlines():
            if reissues_created >= MAX_REISSUES:
                break
            if not (line.startswith('- 🔲') and '⚠️ Inferred from' in line):
                continue
            dm = DATE_PATTERN.search(line)
            if not dm:
                continue
            try:
                item_date = datetime.date.fromisoformat(dm.group(1))
                age_days = (today - item_date).days
            except ValueError:
                continue
            if age_days <= 30:
                continue  # not old enough
            # Extract item text (strip the '- 🔲 ' prefix)
            item_text = re.sub(r'^- 🔲 ', '', line).strip()
            title_key = item_text[:40].strip()
            issue_title = f'feat: {item_text[:90]}'

            # Deduplication check (§42.1 O3)
            try:
                r = subprocess.run(
                    ['gh', 'issue', 'list', '--repo', REPO, '--state', 'open',
                     '--search', title_key[:40], '--json', 'number', '--jq', 'length'],
                    capture_output=True, text=True, timeout=15)
                if int(r.stdout.strip() or '0') > 0:
                    continue  # issue already exists
            except Exception as e:
                print(f'[SCAN 3] re-issue check failed (non-fatal): {e}')
                continue

            # Create re-issue (§42.1 O4)
            try:
                cr = subprocess.run(
                    ['gh', 'issue', 'create', '--repo', REPO,
                     '--title', issue_title,
                     '--label', 'otherness,kind/enhancement,priority/medium',
                     '--body', (f'## Design reference\n'
                                f'- **Design doc**: `docs/design/{fname}`\n'
                                f'- **Section**: `§ Future`\n'
                                f'- **Implements**: {item_text[:100]} (🔲 → ✅)\n\n'
                                f'## Summary\n\n'
                                f'SCAN 3 §42.1 re-issue: this item has been `⚠️ Inferred` for {age_days} days '
                                f'without a corresponding GitHub issue. Auto-created to ensure it enters the queue.\n\n'
                                f'Full item: {item_text}')],
                    capture_output=True, text=True, timeout=15)
                if cr.returncode == 0:
                    reissues_created += 1
                    print(f'[SCAN 3] §42.1 re-issued ({age_days}d old): {issue_title[:60]}')
            except Exception as e:
                print(f'[SCAN 3] re-issue create failed (non-fatal): {e}')
    except Exception as e:
        print(f'[SCAN 3] §42.1 age-check error for {fname} (non-fatal): {e}')

if reissues_created > 0:
    print(f'[SCAN 3] §42.1 created {reissues_created} re-issue(s) for aged inferred items.')
else:
    print('[SCAN 3] §42.1 no aged inferred items needing re-issue.')

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
today_str = today.strftime('%Y-%m-%d')
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

        # §42.1 O1: include (date: YYYY-MM-DD) annotation on new inferred items
        new_item = f'- 🔲 {msg} — ⚠️ Inferred from `{fpath}:{lineno}` ({kind}) (date: {today_str})'

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

## SCAN 5 — Self-updating pressure prompts (design doc 37 §37.1, §37.2)

Evaluate whether the current vision pressure context is still pushing the right things.
When pressure areas are substantially addressed, add a design doc Future item to trigger
a pressure rewrite — the human should not be the one raising the bar.

```bash
python3 - <<'SCAN5_EOF'
import re, os, subprocess, sys

REPO = os.environ.get('REPO', '')

# Step 1: Read the active pressure block from the Step A workflow prompt.
# Design ref: docs/design/37-self-updating-pressure-prompts.md §37.1
#
# Primary source: parse the `prompt:` YAML key of the Step A step in
# .github/workflows/otherness-scheduled.yml (Step A is identified by
# its prompt containing "vibe-vision-auto.md").
# Fallback: search all .github/workflows/*.yml for "Context for this vision scan:".

workflow_dir = '.github/workflows'
pressure_block = ''
pressure_file = None

def _extract_pressure_block(content):
    """Extract the pressure block text from workflow content."""
    m = re.search(
        r'Context for this vision scan:(.*?)(?=For each gap you identify|OTHERNESS_PRESSURE_END|\Z)',
        content, re.DOTALL)
    return m.group(1).strip() if m else ''

def _extract_bullets(block):
    """Extract one entry per bullet line from a pressure block.

    Design ref: docs/design/37-self-updating-pressure-prompts.md §37.2
    Design ref: docs/design/17-vision-evolution-cadence.md §Future (issue-928)
    Each bullet is a distinct scoring unit. Strip leading '- ', trailing '?',
    and return the full bullet text (lowercased) for domain-noun matching.
    Returns list of (raw_bullet_text, domain_nouns) tuples where domain_nouns
    is a list of extracted domain nouns — used for multi-noun evidence matching.

    Domain noun expansion (issue-928): instead of matching the first 30 chars
    of the bullet verbatim (which fails for abstract lenses like "Is the
    onboarding good enough?"), extract concrete domain terms that appear in
    both the bullet and in PR titles / Present items.
    """
    # Domain noun dictionary: concrete terms per domain area.
    # Design ref: docs/design/17-vision-evolution-cadence.md §Future
    DOMAIN_NOUNS = {
        # Onboarding domain
        'onboard', 'setup', 'first-run', 'setup-guide', 'onboarding',
        # Visibility / health domain
        'dashboard', 'health', 'visib', 'visibility', 'progress', 'status',
        'report', 'metrics', 'schema', 'observ',
        # Skills / learning domain
        'learn', 'skill', 'session', 'quality',
        # Agent loop domain
        'coord', 'queue', 'session', 'agent', 'loop', 'phase',
        # Release / throughput domain
        'release', 'throughput', 'meaningful', 'ship',
        # Competitive / vision domain
        'competi', 'vision', 'pressure', 'roadmap',
    }

    bullets = []
    for line in block.splitlines():
        stripped = line.strip()
        if not stripped.startswith('- '):
            continue
        text = stripped[2:].strip().rstrip('?').strip()
        if len(text) < 5:
            continue
        text_lower = text.lower()
        # Extract domain nouns that appear in this bullet text
        found_nouns = [n for n in DOMAIN_NOUNS if n in text_lower]
        # Fallback: if no domain noun found, use first-30-char topic prefix
        if not found_nouns:
            found_nouns = [text_lower[:30]]
        bullets.append((text, found_nouns))
    return bullets

# Primary: parse prompt: section of Step A in otherness-scheduled.yml
SCHEDULED_WORKFLOW = os.path.join(workflow_dir, 'otherness-scheduled.yml')
if os.path.isfile(SCHEDULED_WORKFLOW):
    try:
        content = open(SCHEDULED_WORKFLOW).read()
        # Find the Step A prompt block: the step whose prompt: contains vibe-vision-auto.md
        # Extract indented block after `prompt: |` that contains vibe-vision-auto.md
        step_blocks = re.findall(r'(prompt:\s*\|[^\S\n]*\n(?:(?:[ \t]+[^\n]*\n?|\n)*))',
                                 content)
        for block_str in step_blocks:
            if 'vibe-vision-auto.md' in block_str:
                # Found Step A's prompt — extract the pressure block from it
                extracted = _extract_pressure_block(block_str)
                if extracted:
                    pressure_block = extracted
                    pressure_file = 'otherness-scheduled.yml (Step A prompt)'
                    break
    except Exception as e:
        print(f'[SCAN 5] Warning: could not parse {SCHEDULED_WORKFLOW}: {e}', file=sys.stderr)

# Fallback: search all workflow files for Context for this vision scan:
if not pressure_block and os.path.isdir(workflow_dir):
    print('[SCAN 5] Falling back to workflow scan (Step A prompt not found in otherness-scheduled.yml)')
    for fname in sorted(os.listdir(workflow_dir)):
        if not fname.endswith(('.yml', '.yaml')): continue
        fpath = os.path.join(workflow_dir, fname)
        try:
            content = open(fpath).read()
            if 'Context for this vision scan:' in content or 'OTHERNESS_PRESSURE_START' in content:
                extracted = _extract_pressure_block(content)
                if extracted:
                    pressure_block = extracted
                    pressure_file = fname
                    break
        except Exception:
            continue

# Extract bullets — one per bullet line (§37.2: per-bullet scoring unit)
pressure_bullets = _extract_bullets(pressure_block) if pressure_block else []

if not pressure_file or not pressure_bullets:
    print('[SCAN 5] No pressure block found — skipping.')
    sys.exit(0)

print(f'[SCAN 5] Found pressure block in {pressure_file}: {len(pressure_bullets)} bullets')

# Step 2: Build evidence corpus — merged PRs (last 20) AND design doc Present items.
# Design ref: docs/design/37-self-updating-pressure-prompts.md §37.2
# Both sources contribute evidence. Each PR title = 1 evidence item.
# Each ✅ Present line in any docs/design/*.md = 1 evidence item.

# 2a: Collect recent merged PR titles
try:
    pr_titles = subprocess.check_output(
        ['gh', 'pr', 'list', '--repo', REPO, '--state', 'merged',
         '--limit', '20', '--json', 'title', '--jq', '.[].title'],
        text=True, timeout=20).lower().splitlines()
    pr_titles = [t.strip() for t in pr_titles if t.strip()]
except Exception:
    pr_titles = []

# 2b: Collect ✅ Present items from all docs/design/*.md files
present_items = []
design_dir = 'docs/design'
if os.path.isdir(design_dir):
    for fname in sorted(os.listdir(design_dir)):
        if not fname.endswith('.md'):
            continue
        try:
            doc_content = open(os.path.join(design_dir, fname)).read()
            present_match = re.search(
                r'^## Present.*?\n(.*?)(?=^## |\Z)', doc_content,
                re.MULTILINE | re.DOTALL)
            if present_match:
                items = re.findall(r'^- ✅ (.+)', present_match.group(1), re.MULTILINE)
                present_items.extend(i.lower().strip() for i in items)
        except Exception:
            pass

# 2c: Per-bullet scoring — §37.2 spec O1–O5
# A bullet is "addressed" when ≥2 distinct evidence items match ANY of its domain nouns.
# Evidence items: PR titles + Present doc items. Substring match on each domain noun.
# Design ref: docs/design/17-vision-evolution-cadence.md §Future (issue-928):
# Uses domain_nouns list (from _extract_bullets) instead of first-30-char prefix,
# so abstract lens bullets like "Is the onboarding good enough?" resolve to concrete
# nouns ('onboard', 'setup', ...) that appear in PR titles and Present items.

addressed_bullets = 0
total_bullets = len(pressure_bullets)

for idx, (bullet_text, domain_nouns) in enumerate(pressure_bullets, 1):
    match_count = 0
    matched_evidence = set()
    # Count evidence items matching ANY domain noun (each evidence item counted once)
    for pr_title in pr_titles:
        if any(noun in pr_title for noun in domain_nouns) and pr_title not in matched_evidence:
            match_count += 1
            matched_evidence.add(pr_title)
    for pitem in present_items:
        if any(noun in pitem for noun in domain_nouns) and pitem not in matched_evidence:
            match_count += 1
            matched_evidence.add(pitem)
    is_addressed = match_count >= 2
    if is_addressed:
        addressed_bullets += 1
    # Per-bullet audit log (§37.2 O5)
    print(f'[SCAN 5] Bullet {idx}/{total_bullets}: "{bullet_text[:40]}" '
          f'(nouns={domain_nouns[:3]}) → addressed={is_addressed} ({match_count} matches)')

ratio = addressed_bullets / total_bullets if total_bullets > 0 else 0
print(f'[SCAN 5] Pressure addressed: {addressed_bullets}/{total_bullets} bullets ({ratio:.0%})')

# Step 3: If addressed ratio >= 60%, add a Future item to trigger pressure rewrite
# Design ref: docs/design/37-self-updating-pressure-prompts.md §37.3 (separate item)
# This step preserved from §37.1; scoring now uses per-bullet ratio from §37.2.
STALENESS_THRESHOLD = 0.60

if ratio >= STALENESS_THRESHOLD:
    print(f'[SCAN 5] Pressure context is ≥{STALENESS_THRESHOLD:.0%} addressed — adding rewrite reminder.')

    # Find best design doc to attach to (doc 37 for self-updating pressure prompts)
    target_doc = None
    for fname in sorted(os.listdir(design_dir) if os.path.isdir(design_dir) else []):
        if fname.startswith('37-') or 'pressure' in fname:
            target_doc = fname
            break
    if not target_doc:
        for fname in sorted(os.listdir(design_dir) if os.path.isdir(design_dir) else []):
            if fname.startswith('28-') or 'dual-step' in fname or 'scheduled' in fname:
                target_doc = fname
                break
    if not target_doc:
        # Fallback: first design doc
        docs = sorted(os.listdir(design_dir)) if os.path.isdir(design_dir) else []
        target_doc = next((f for f in docs if f.endswith('.md')), None)

    if target_doc:
        fpath = os.path.join(design_dir, target_doc)
        try:
            content = open(fpath).read()
            new_item = (
                f'- 🔲 Rewrite vision pressure context in scheduled workflow: '
                f'{addressed_bullets}/{total_bullets} pressure bullets addressed '
                f'(≥2 matches each in merged PRs + design doc Present items) — '
                f'the bar needs to be raised. Update the "Context for this vision scan:" '
                f'block to push on the remaining open gaps. '
                f'⚠️ Inferred from pressure staleness scan: {ratio:.0%} addressed.'
            )
            # Only add if not already present
            if 'Rewrite vision pressure context' not in content:
                # Find Future section
                if '## Future' in content:
                    future_pos = content.index('## Future')
                    # Find end of future section marker (first line after header)
                    lines = content[future_pos:].split('\n')
                    insert_after = future_pos + len(lines[0]) + len(lines[1]) + 2
                    content = content[:insert_after] + '\n' + new_item + '\n' + content[insert_after:]
                else:
                    content += f'\n## Future (🔲)\n\n{new_item}\n'
                with open(fpath, 'w') as f:
                    f.write(content)
                print(f'[SCAN 5] Added pressure rewrite item to {target_doc}')
            else:
                print(f'[SCAN 5] Pressure rewrite item already present — skipping.')
        except Exception as e:
            print(f'[SCAN 5] Error updating {target_doc}: {e}')
     else:
         print('[SCAN 5] No design doc found to attach pressure rewrite item to.')
else:
    print(f'[SCAN 5] Pressure context still relevant ({ratio:.0%} addressed < {STALENESS_THRESHOLD:.0%} threshold) — no action needed.')

# Step 4 (42.4): Time-based staleness trigger — independent of keyword match rate.
# Design ref: docs/design/42-vision-scan-to-shipped-gap.md §42.4 (🔲 → ✅)
#
# A pressure context can become stale not because keywords were shipped,
# but because the project's focus shifted (e.g. agent loop → onboarding).
# If the pressure block has not been rewritten in >30 days, add a Future
# item regardless of keyword match rate.
#
# How to detect age: look for a <!-- pressure-rewritten: YYYY-MM-DD --> comment
# in the pressure block or in the scheduled workflow file. If the comment is
# absent, treat the age as unknown (conservative: add the rewrite reminder).
# If present, parse the date and compare to today.

PRESSURE_STALE_DAYS = int(subprocess.check_output(
    ['python3', '-c', '''
import re
section = None
try:
    for line in open("otherness-config.yaml"):
        s = re.match(r"^(\w[\w_]*):", line)
        if s: section = s.group(1)
        if section == "vision":
            m = re.match(r"\s+pressure_max_age_days:\s*(\d+)", line)
            if m: print(m.group(1)); exit()
except: pass
print("14")
'''], text=True, timeout=5).strip() or '14')  # configurable max age; default 14 days (design doc 37.12)

# Extract rewrite date from workflow content
rewrite_date = None
if pressure_file and os.path.isfile(SCHEDULED_WORKFLOW):
    try:
        content = open(SCHEDULED_WORKFLOW).read()
        dm = re.search(r'<!--\s*pressure-rewritten:\s*(\d{4}-\d{2}-\d{2})\s*-->', content)
        if dm:
            import datetime
            rewrite_date = datetime.date.fromisoformat(dm.group(1))
    except Exception:
        pass

if rewrite_date is None:
    # No timestamp found — conservative: treat as if it has never been rewritten.
    # This ensures the check fires on the first scan after this feature ships.
    pressure_age_days = PRESSURE_STALE_DAYS + 1  # triggers the check
    age_desc = 'no rewrite timestamp found (conservative: treating as stale)'
else:
    import datetime
    pressure_age_days = (datetime.date.today() - rewrite_date).days
    age_desc = f'{pressure_age_days}d since last rewrite ({rewrite_date})'

print(f'[SCAN 5 §42.4] Pressure age: {age_desc}')

if pressure_age_days > PRESSURE_STALE_DAYS:
    # Mandatory trigger (design doc 37.12 O3): max-age is independent of addressed ratio.
    # Unlike the ratio-based trigger, this fires regardless of how many pressure bullets
    # were addressed — a stale pressure context is a stale context, period.
    print(f'[SCAN 5 §42.4] Pressure context is >{PRESSURE_STALE_DAYS}d old — mandatory time-based rewrite reminder (37.12).')

    target_doc = None
    if os.path.isdir(design_dir):
        for fname in sorted(os.listdir(design_dir)):
            if fname.startswith('37-') or 'pressure' in fname:
                target_doc = fname
                break
        if not target_doc:
            for fname in sorted(os.listdir(design_dir)):
                if fname.startswith('42-') or 'vision-scan' in fname or 'shipped-gap' in fname:
                    target_doc = fname
                    break
        if not target_doc:
            docs = sorted(os.listdir(design_dir))
            target_doc = next((f for f in docs if f.endswith('.md')), None)

    if target_doc:
        fpath = os.path.join(design_dir, target_doc)
        try:
            content = open(fpath).read()
            new_item = (
                f'- 🔲 Rewrite vision pressure context (time-based staleness): '
                f'pressure block is >{PRESSURE_STALE_DAYS}d old ({age_desc}). '
                f'The bar must be raised even when keyword match rate is below the threshold — '
                f'time-based staleness means the system\'s focus has shifted without the pressure '
                f'prompts keeping pace. Update the "Context for this vision scan:" block. '
                f'Add a <!-- pressure-rewritten: YYYY-MM-DD --> comment after rewriting. '
                f'⚠️ Inferred from SCAN 5 §42.4 time-based staleness trigger.'
            )
            REWRITE_MARKER = 'Rewrite vision pressure context (time-based staleness)'
            if REWRITE_MARKER not in content:
                if '## Future' in content:
                    future_pos = content.index('## Future')
                    lines = content[future_pos:].split('\n')
                    insert_after = future_pos + len(lines[0]) + len(lines[1]) + 2
                    content = content[:insert_after] + '\n' + new_item + '\n' + content[insert_after:]
                else:
                    content += f'\n## Future (🔲)\n\n{new_item}\n'
                with open(fpath, 'w') as f:
                    f.write(content)
                print(f'[SCAN 5 §42.4] Added time-based rewrite item to {target_doc}')
            else:
                print(f'[SCAN 5 §42.4] Time-based rewrite item already present — skipping.')
        except Exception as e:
            print(f'[SCAN 5 §42.4] Error updating {target_doc}: {e}')
    else:
         print('[SCAN 5 §42.4] No design doc found to attach item to.')
else:
    print(f'[SCAN 5 §42.4] Pressure context is fresh ({age_desc} ≤ {PRESSURE_STALE_DAYS}d) — no time-based trigger.')

SCAN5_EOF
```

## SCAN 5 — YAML safety gate (design doc 28 §28.1)

**When implementing §37.5 (actual workflow file rewrite)**: after writing the new pressure
block to `.github/workflows/otherness-scheduled.yml`, validate YAML syntax before committing.

```bash
# [AI-STEP — activate when §37.5 is implemented] After writing the pressure block:
# validate YAML syntax and revert on error (design doc 28 §28.1)
WORKFLOW_FILE=".github/workflows/otherness-scheduled.yml"
if [ -f "$WORKFLOW_FILE" ] && git diff --quiet "$WORKFLOW_FILE" 2>/dev/null; then
  : # no changes — skip check
elif [ -f "$WORKFLOW_FILE" ]; then
  YAML_CHECK=$(python3 -c "
import sys
try:
    import yaml
except ImportError:
    print('SKIP'); sys.exit(0)
try:
    yaml.safe_load(open('$WORKFLOW_FILE').read())
    print('OK')
except yaml.YAMLError as e:
    print(f'FAIL: {e}')
" 2>/dev/null || echo "SKIP")

  if echo "$YAML_CHECK" | grep -q "^FAIL"; then
    echo "[SCAN 5 YAML ERROR] Invalid YAML after pressure rewrite — reverting."
    git checkout -- "$WORKFLOW_FILE" 2>/dev/null || true
    gh issue comment $REPORT_ISSUE --repo $REPO \
      --body "[SCAN 5 YAML ERROR | VIBE-VISION-AUTO] Pressure rewrite produced invalid YAML in $WORKFLOW_FILE — reverted. Detail: $YAML_CHECK" 2>/dev/null || true
  else
    echo "[SCAN 5] YAML syntax valid after pressure rewrite."
  fi
fi
```

---

## GAP STAGNATION RATIO (design doc 42.2)

Compute gap stagnation metrics from this scan run and append to report comment.

```bash
# Count new_gaps (⚠️ Inferred items added to docs/ this scan run)
NEW_GAPS=$(git diff docs/ 2>/dev/null | \
  grep '^+' | grep -v '^+++' | \
  grep -c '⚠️ Inferred\|⚠️ Observed' 2>/dev/null || echo 0)

# Count gaps_shipped (🔲 lines removed → ✅ transitions this run)
GAPS_SHIPPED=$(git diff docs/ 2>/dev/null | \
  grep '^-' | grep -v '^---' | \
  grep -c '🔲' 2>/dev/null || echo 0)

# Count gaps_aged_30d (open ⚠️ Inferred GitHub issues older than 30 days)
GAPS_AGED_30D=$(python3 - <<'GAP_STALE_EOF'
import subprocess, json, datetime, os, re

REPO = os.environ.get('REPO', '')
if not REPO:
    print(0); exit(0)

try:
    r = subprocess.run(
        ['gh', 'issue', 'list', '--repo', REPO, '--state', 'open',
         '--search', 'Inferred', '--limit', '200',
         '--json', 'number,title,createdAt'],
        capture_output=True, text=True, timeout=15)
    if r.returncode != 0:
        print(0); exit(0)
    issues = json.loads(r.stdout or '[]')
except Exception:
    print(0); exit(0)

threshold = datetime.datetime.now(datetime.timezone.utc) - datetime.timedelta(days=30)
count = 0
for issue in issues:
    try:
        created = datetime.datetime.fromisoformat(
            issue.get('createdAt', '').replace('Z', '+00:00'))
        if created < threshold:
            count += 1
    except Exception:
        pass
print(count)
GAP_STALE_EOF
)

# Compute stagnation ratio
GAP_STAGNATION=$(python3 -c "
new_gaps = int('${NEW_GAPS:-0}')
gaps_shipped = int('${GAPS_SHIPPED:-0}')
gaps_aged = int('${GAPS_AGED_30D:-0}')
denominator = new_gaps + gaps_shipped
if denominator == 0:
    ratio_str = 'N/A (no new/shipped gaps this run)'
else:
    ratio = gaps_aged / denominator
    ratio_str = f'{ratio:.1f}'
    if ratio > 2.0:
        ratio_str += f' [⚠️ GAP STAGNATION: {gaps_aged} old gaps are not shipping]'
print(f'Gap stagnation: new={new_gaps} shipped={gaps_shipped} aged_30d={gaps_aged} ratio={ratio_str}')
" 2>/dev/null || echo "Gap stagnation: metrics unavailable")

echo "[VIBE-VISION-AUTO] $GAP_STAGNATION"
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
- Scan 4: deprecate 🔲 Future items stale >90 days with no open issue
- Scan 5: self-updating pressure prompts — flag stale pressure context when ≥60% addressed

Signed-off-by: otherness[bot] <otherness[bot]@users.noreply.github.com>" 2>/dev/null || true

  echo "[VIBE-VISION-AUTO] Vision scan committed. Step B will see updated docs."

  # Post to report issue
  gh issue comment $REPORT_ISSUE --repo $REPO \
    --body "[🌀 VIBE-VISION-AUTO] Autonomous vision scan complete.
$SUMMARY
$GAP_STAGNATION
Step B (run) will pick up any updated queue items." 2>/dev/null || true
else
  echo "[VIBE-VISION-AUTO] No doc changes — design docs are current."
  # Still report gap stagnation even when no doc changes (O4)
  gh issue comment $REPORT_ISSUE --repo $REPO \
    --body "[🌀 VIBE-VISION-AUTO] Autonomous vision scan complete (no doc changes).
$GAP_STAGNATION" 2>/dev/null || true
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
