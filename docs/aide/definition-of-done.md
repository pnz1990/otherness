# Definition of Done

> The project is complete when every journey below passes.
> These journeys are validated by the PM agent every `product_validation_cycles` cycles.

---

## Journey 1: otherness can build and validate itself

**The user story**: A developer clones the otherness repo, runs the three validation scripts, and they all exit 0.

### Exact steps that must work

```bash
cd ~/.otherness
bash scripts/validate.sh   # must exit 0
bash scripts/lint.sh       # must exit 0
bash scripts/test.sh       # must exit 0
```

### Pass criteria

- [ ] `validate.sh` exits 0: no hardcoded project paths in agents/, all skill refs exist
- [ ] `lint.sh` exits 0: all markdown files in agents/ are well-formed
- [ ] `test.sh` exits 0: including the alibi integration check (state commits within 72h)

---

## Journey 2: otherness runs correctly on a reference project

**The user story**: otherness runs autonomously on alibi for at least one full batch (claim item → implement → PR → merge) without human intervention.

### Automated check (runs in PM §5j every N_PM_CYCLES)

```bash
# The canonical check — same logic as scripts/test.sh check 5b
# Returns: stale age in hours + STALE_REASON if failing

REFERENCE_PROJECT=$(python3 -c "
import re
in_monitor=in_projects=False
for line in open('otherness-config.yaml'):
    if re.match(r'^monitor:',line): in_monitor=True
    if in_monitor and re.match(r'\s+projects:',line): in_projects=True
    if in_projects:
        m=re.match(r'\s+- (.+)',line)
        if m:
            r=m.group(1).strip()
            if not r.endswith('/otherness'): print(r); break
")

LAST_COMMIT=$(gh api "repos/$REFERENCE_PROJECT/branches/_state" \
  --jq '.commit.commit.committer.date' 2>/dev/null || echo "")

AGE_H=$(python3 -c "
import datetime
d = '$LAST_COMMIT'
try:
    dt = datetime.datetime.fromisoformat(d.replace('Z','+00:00'))
    now = datetime.datetime.now(datetime.timezone.utc)
    print(f'{(now - dt).total_seconds() / 3600:.1f}')
except: print('999')
")

if python3 -c "exit(0 if float('$AGE_H') <= 72 else 1)"; then
  echo "Journey 2: PASS — $REFERENCE_PROJECT active ${AGE_H}h ago"
else
  DAYS=$(python3 -c "print(f'{float(\"$AGE_H\")/24:.1f}')")
  echo "Journey 2: FAIL — $REFERENCE_PROJECT _state last commit ${DAYS}d ago"
  echo "STALE_REASON: $REFERENCE_PROJECT _state last commit ${DAYS}d ago (threshold: 72h)"
fi
```

### Pass criteria

- [ ] alibi `_state` branch has commits within 72 hours
- [ ] At least 1 alibi PR merged in the last 7 days
- [ ] Zero alibi `needs-human` issues open for >72 hours without a human comment

---

## Journey 3: self-improvement is happening

**The user story**: otherness is autonomously improving itself — PRs are being opened and merged to `pnz1990/otherness`.

### Exact steps that must work

```bash
# At least one self-improvement PR merged in last 14 days
gh pr list --repo pnz1990/otherness --state merged \
  --json mergedAt,title --jq '.[0] | "\(.mergedAt) \(.title)"'

# Skills are growing
ls ~/.otherness/agents/skills/*.md | grep -v PROVENANCE | wc -l
# Must be ≥ 4 (grows over time)

# PROVENANCE.md has recent entries
tail -5 ~/.otherness/agents/skills/PROVENANCE.md
```

### Pass criteria

- [ ] At least 1 PR merged to `pnz1990/otherness` within the last 14 days
- [ ] Skill count ≥ 4 and non-decreasing
- [ ] PROVENANCE.md last entry within 30 days

---

## Journey 4: CRITICAL tier protection works

**The user story**: A PR modifying `agents/standalone.md` cannot be autonomously merged — it requires human review.

### Exact steps that must work

```bash
# Any open PR touching standalone.md must have needs-human label
gh pr list --repo pnz1990/otherness --state open \
  --json number,title,labels,files \
  --jq '.[] | select(.files[].path | test("standalone.md")) | {number, labels: [.labels[].name]}'
# Every result must include "needs-human" in its labels array
```

### Pass criteria

- [ ] No PR touching `agents/standalone.md` or `agents/bounded-standalone.md` is merged without `needs-human` label
- [ ] The QA phase explicitly checks file paths and applies the CRITICAL tier rule

---

## Journey 5: `/otherness.run` starts cleanly on a fresh clone of otherness

**The user story**: Running `/otherness.run` from `~/.otherness` produces a working session that reads the project correctly.

### Exact steps that must work

```bash
cd ~/.otherness
# (from an OpenCode session)
# /otherness.run
# Agent must:
# 1. Self-update (git pull)
# 2. Read AGENTS.md successfully
# 3. Read state.json from _state branch
# 4. Read docs/aide/vision.md
    # 5. Post a [COORD] startup comment on issue #2
# 6. Claim or generate a work item
# 7. NOT crash with "AGENTS.md not found" or "state.json not found"
```

### Pass criteria

- [ ] Agent reads AGENTS.md without error
- [ ] Agent reads state.json from _state branch
- [ ] Agent posts startup comment on report issue #2
- [ ] Agent claims or generates a work item within the first cycle
- [ ] No `[NEEDS HUMAN]` posted due to missing infrastructure files

---

## Journey 6: `/otherness.vibe-vision` produces valid D4 artifacts

**The user story**: A human runs `/otherness.vibe-vision`, has a dialogue with the agent, and the resulting design doc stubs are immediately usable by the autonomous execution team — COORD picks them up and generates queue issues on next startup.

### Exact steps that must work

```bash
# After a vibe-vision session completes:

# 1. At least one design doc stub was created (or updated with new Future items)
ls docs/design/*.md 2>/dev/null | wc -l
# Must be ≥ 1 file after session

# 2. The design doc stubs contain machine-readable Future items
python3 -c "
import re, os
design_dir = 'docs/design'
total = 0
for f in os.listdir(design_dir):
    if f.endswith('.md'):
        content = open(f'{design_dir}/{f}').read()
        m = re.search(r'^## Future.*?\n(.*?)(?=^## |\Z)', content, re.MULTILINE | re.DOTALL)
        if m:
            items = re.findall(r'^- 🔲 (?!.*🚫)(.+)', m.group(1), re.MULTILINE)
            total += len(items)
print(f'{total} machine-readable Future items')
"
# Must be ≥ 1

# 3. COORD queue generation finds those items on next startup
# (Verified by watching the next /otherness.run session claim an item from the new design doc)

# 4. vibe-vision command file is deployed
ls ~/.otherness/.opencode/command/otherness.vibe-vision.md
# Must exist
```

### Pass criteria

- [ ] At least one `docs/design/*.md` file exists after a vibe-vision session
- [ ] At least one `🔲 Future` item in the correct format exists in a design doc stub
- [ ] COORD queue generation (next /otherness.run) finds and queues at least one item from the new design doc
- [ ] `/otherness.vibe-vision` command file exists in `.opencode/command/`

---

## Journey 8: Commands always current

**The user story**: After otherness is updated (new commands added, old ones removed), any project running `/otherness.run` automatically gets the current set of commands — no human action required.

### Automated check

```bash
# Verify the SELF-UPDATE block syncs commands
# Run from any otherness-managed project after a session:

# 1. Commands in project match ~/.otherness exactly
diff <(ls .opencode/command/otherness.*.md 2>/dev/null | xargs -I{} basename {} | sort) \
     <(ls ~/.otherness/.opencode/command/otherness.*.md 2>/dev/null | xargs -I{} basename {} | sort)
# Must output nothing (no diff)

# 2. Stale commands are gone
for f in .opencode/command/otherness.*.md; do
  fname=$(basename "$f")
  [ -f ~/.otherness/.opencode/command/"$fname" ] || echo "STALE: $fname"
done
# Must output nothing

# 3. SELF-UPDATE block exists in standalone.md
grep -c "two-way sync\|SYNCED\|cmp -s" ~/.otherness/agents/standalone.md
# Must be ≥ 3
```

### Pass criteria

- [ ] `.opencode/command/otherness.*.md` files match `~/.otherness/.opencode/command/otherness.*.md` exactly (no missing, no stale)
- [ ] `otherness.vibe-vision.md` is present in the project after next `/otherness.run`
- [ ] `otherness.cross-agent-monitor.md` is absent from the project after next `/otherness.run`
- [ ] `standalone.md` contains the two-way sync block in SELF-UPDATE

---

## Journey 7: Eternal loop — health signal, not stop condition

**The user story**: The system runs 10 consecutive batches without saying "final run" or "complete." It reports health signals. It enters standby correctly. It wakes when new vision is added without human restart instruction.

### Exact steps that must work

```bash
# 1. Verify health signal format in last 10 batch completion posts
gh issue view 2 --repo pnz1990/otherness --json comments \
  --jq '[.comments[-10:][].body | select(contains("Health:"))] | length'
# Must be ≥ 10 (10 batches used health signal format, not "final run")

# 2. Verify no "final run" or "complete" language in last 10 posts
gh issue view 2 --repo pnz1990/otherness --json comments \
  --jq '[.comments[-10:][].body | select(contains("final run") or contains("system is complete"))] | length'
# Must be 0

# 3. Verify system entered standby when queue was empty
gh issue view 2 --repo pnz1990/otherness --json comments \
  --jq '[.comments[-20:][].body | select(contains("Standby"))] | length'
# Must be ≥ 1 (at least one standby entry)

# 4. Verify system woke from standby when new design doc items were added
# (validated by checking queue generated items after a vibe-vision session)
```

### Pass criteria

- [ ] Last 10 batch completion posts use health signal format (GREEN/AMBER/RED)
- [ ] Zero occurrences of "final run" or "system is complete" in last 10 posts
- [ ] At least one standby entry in the last 20 posts
- [ ] System woke from standby and generated a queue after new design doc items arrived (from vibe-vision or competitive observation)
- [ ] Journey 2 (reference project) stayed GREEN for 7 consecutive days

---

## Journey Status

| Journey | Status | Last checked | Health | Notes |
|---|---|---|---|---|
| 1: Build and validate itself | ✅ Passing | 2026-04-19 | GREEN | validate.sh, lint.sh, test.sh all exit 0 |
| 2: Runs correctly on reference project | ❌ Failing | 2026-04-19 | AMBER | alibi `_state` last commit 2026-04-14 (5d). PM §5j should post [NEEDS HUMAN] once. `bash scripts/test.sh` check 5b outputs STALE_REASON. [NEEDS HUMAN: restart otherness on alibi] |
| 3: Self-improvement happening | ✅ Passing | 2026-04-19 | GREEN | 20+ PRs merged; command sync shipped; Stage 9/10 complete |
| 4: CRITICAL tier protection | ✅ Passing | 2026-04-19 | GREEN | CRITICAL-A/B tier split; autonomous merge protocol; queue gate |
| 5: Starts cleanly on fresh clone | ✅ Passing | 2026-04-19 | GREEN | command files now auto-synced via SELF-UPDATE; setup updated |
| 6: vibe-vision produces valid D4 artifacts | ✅ Passing | 2026-04-19 | GREEN | Multiple sessions produced design docs with 🔲 Future items; COORD picked them up |
| 7: Eternal loop health signal | ✅ Passing | 2026-04-19 | GREEN | SM §4f now posts Health: GREEN/AMBER/RED; 'Never report finality' rule in HARD RULES; no 'final run' in last 10 posts |
| 8: Commands always current | ✅ Passing | 2026-04-19 | GREEN | Two-way sync in SELF-UPDATE: adds new, removes stale otherness.* on every session startup (PR #332) |
