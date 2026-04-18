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

### Exact steps that must work

```bash
# Verify alibi _state shows recent activity
gh api repos/pnz1990/alibi/branches/_state \
  --jq '.commit.commit.committer.date'
# Must be within 72 hours

# Verify at least one PR merged recently
gh pr list --repo pnz1990/alibi --state merged \
  --json mergedAt --jq '.[0].mergedAt'
# Must be within 7 days

# Verify no stuck [NEEDS HUMAN] blocking the queue
gh issue list --repo pnz1990/alibi --label needs-human --state open \
  --json number,title | python3 -c "
import json,sys
issues = json.load(sys.stdin)
stale = [i for i in issues]  # any is a flag
print(f'{len(stale)} needs-human issues open')
"
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

## Journey Status

| Journey | Status | Last checked | Notes |
|---|---|---|---|
| 1: Build and validate itself | ✅ Passing | 2026-04-17 | validate.sh, lint.sh, test.sh all exit 0 |
| 2: Runs correctly on reference project | ❌ Failing | 2026-04-17 | alibi `_state` last commit 2026-04-14 (>72h). `features: {}` empty — no session has run. [NEEDS HUMAN: restart otherness on alibi] |
| 3: Self-improvement happening | ✅ Passing | 2026-04-17 | PR merged 2026-04-17; 11 skills; PROVENANCE last entry 2026-04-15 |
| 4: CRITICAL tier protection | ✅ Passing | 2026-04-17 | No open CRITICAL PRs without needs-human; self-review protocol working |
| 5: Starts cleanly on fresh clone | ✅ Passing | 2026-04-17 | 9 command files present; state seeds correctly |
| 6: vibe-vision produces valid D4 artifacts | 🔲 Not validated | 2026-04-18 | Journey 6 added. Requires a live vibe-vision session to validate. |
