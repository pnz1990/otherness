# 28: Dual-Step Scheduled Workflow — Vision First, Then Build

> Status: Active | Created: 2026-04-20
> Applies to: otherness itself and all managed projects

---

## The problem this solves

The current scheduled workflow runs a single step: `/otherness.run` (the SDLC loop).
That loop implements from the existing queue. If the queue is stale, sparse, or
misaligned with actual project direction, the loop burns tokens implementing the wrong
things.

Vision is the upstream constraint. Without a regular vision step, the queue drifts
toward mechanical completions rather than meaningful forward motion. The PM phase
catches this (§5m Inferred ratio) but only after it has already happened.

The fix: **every scheduled run does vision first, then implementation**. The workflow
has two OpenCode steps:

1. **Step A — Vision** (`otherness.vibe-vision`): reads the project, checks whether
   the roadmap/design docs reflect the current state of the codebase, and advances
   the `🔲 Future` frontier. Writes to `docs/` only. Always runs.

2. **Step B — Run** (`otherness.run`): the full SDLC loop. Picks up the
   freshly-updated queue from Step A and implements.

Both steps run in the same GitHub Actions job, on the same checkout, sequentially.
Step B always sees the vision Step A just wrote.

---

## Why this matters

- **Queue quality**: Step A ensures the queue has concrete, design-backed items
  before Step B tries to implement them. No more `[AI-STEP]` stubs in the queue.
- **Vision freshness**: Vision evolves every batch, not only when a human runs
  `/otherness.vibe-vision` manually.
- **Self-correcting direction**: If a feature shipped in Step B turns out to need
  a design follow-up, Step A in the _next_ run catches the gap and adds it to
  `🔲 Future`.

---

## The mechanism

### Workflow change

The `otherness-scheduled.yml` workflow gains a second `uses: anomalyco/opencode/github@...`
step. The first step runs the vision command; the second runs the SDLC loop.

```yaml
- name: Otherness — Vision (Step A)
  uses: anomalyco/opencode/github@<SHA>
  env:
    AWS_REGION:          us-east-1
    GH_TOKEN:            ${{ secrets.GH_TOKEN }}
    GITHUB_TOKEN:        ${{ secrets.GH_TOKEN }}
    OPENCODE_PERMISSION: '{"bash":"allow","read":"allow","edit":"allow","write":"allow","glob":"allow","grep":"allow","list":"allow","external_directory":"allow","webfetch":"allow","task":"allow","todowrite":"allow","skill":"allow"}'
  with:
    model: amazon-bedrock/global.anthropic.claude-sonnet-4-6
    prompt: |
      AGENTS_PATH=$(python3 -c "
      import re, os
      section = None
      for line in open('otherness-config.yaml'):
          s = re.match(r'^(\w[\w_]*):', line)
          if s: section = s.group(1)
          if section == 'maqa':
              m = re.match(r'^\s+agents_path:\s*[\"\'']?([^\"\'#\n]+)[\"\'']?', line)
              if m: print(os.path.expanduser(m.group(1).strip())); break
      " 2>/dev/null || echo "$HOME/.otherness/agents")
      Read and follow $AGENTS_PATH/vibe-vision.md.

- name: Otherness — Run (Step B)
  uses: anomalyco/opencode/github@<SHA>
  env:
    AWS_REGION:          us-east-1
    GH_TOKEN:            ${{ secrets.GH_TOKEN }}
    GITHUB_TOKEN:        ${{ secrets.GH_TOKEN }}
    OPENCODE_PERMISSION: '{"bash":"allow","read":"allow","edit":"allow","write":"allow","glob":"allow","grep":"allow","list":"allow","external_directory":"allow","webfetch":"allow","task":"allow","todowrite":"allow","skill":"allow"}'
  with:
    model: amazon-bedrock/global.anthropic.claude-sonnet-4-6
    prompt: |
      AGENTS_PATH=$(python3 -c "
      import re, os
      section = None
      for line in open('otherness-config.yaml'):
          s = re.match(r'^(\w[\w_]*):', line)
          if s: section = s.group(1)
          if section == 'maqa':
              m = re.match(r'^\s+agents_path:\s*[\"\'']?([^\"\'#\n]+)[\"\'']?', line)
              if m: print(os.path.expanduser(m.group(1).strip())); break
      " 2>/dev/null || echo "$HOME/.otherness/agents")
      Read and follow $AGENTS_PATH/standalone.md.
```

### What Step A (vibe-vision) does

The `vibe-vision.md` agent is already implemented. It:
- Reads the codebase and current design docs
- Identifies shipped items still marked `🔲 Future` → promotes to `✅ Present`
- Identifies gaps in the design docs → adds `🔲 Future` items
- Identifies stale `✅ Present` items that no longer match code → marks `⚠️ Stale`
- Commits to `docs/` on the session branch (Step B sees the commits immediately)

Step A does **not** create PRs or merge. It writes to `docs/aide/` and `docs/design/`
only. Step B's SM phase §4g will merge the session branch (which now includes
Step A's doc commits) at end of batch.

### What Step B (run) does differently

Nothing changes in `standalone.md`. Step B simply finds a richer queue because
Step A just populated it. The COORD phase `§1f` minimum queue depth guard still fires
if the queue is empty — but Step A should have prevented that.

### Failure isolation

If Step A fails (e.g., LLM timeout), Step B still runs. Step B reads the last
vision state from `_state` handoff and proceeds normally. A failed Step A is
non-blocking.

---

## Config flag: `schedule.vibe_vision_step`

Projects can opt out of Step A if they have no design docs (or their vision is
deliberately human-only):

```yaml
schedule:
  cron: "0 * * * *"
  model: amazon-bedrock/global.anthropic.claude-sonnet-4-6
  api_key_secret: "ANTHROPIC_API_KEY"
  vibe_vision_step: true   # default: true. Set false to skip Step A.
```

The workflow reads this flag before running Step A:

```bash
VIBE_VISION=$(python3 -c "
import re
section = None
for line in open('otherness-config.yaml'):
    s = re.match(r'^(\w[\w_]*):', line)
    if s: section = s.group(1)
    if section == 'schedule':
        m = re.match(r'\s+vibe_vision_step:\s*(true|false)', line)
        if m: print(m.group(1)); break
" 2>/dev/null || echo "true")
[ "$VIBE_VISION" = "false" ] && echo "::notice::Skipping vibe-vision step (disabled in config)" && exit 0
```

---

## Rollout to managed projects

All managed projects listed in `monitor.projects` in `otherness-config.yaml` get
this workflow update. The SM cross-project monitoring step detects that the project
is using the single-step workflow and creates an issue to upgrade it.

### Detection heuristic (SM §4a)

```bash
# For each monitored project, check if their scheduled workflow has 2 opencode steps
gh api "repos/$proj/contents/.github/workflows" --jq '.[].name' 2>/dev/null | \
  grep -i "schedule\|otherness" | while read wf; do
  content=$(gh api "repos/$proj/contents/.github/workflows/$wf" --jq '.content' | base64 -d 2>/dev/null)
  count=$(echo "$content" | grep -c "anomalyco/opencode/github" || echo 0)
  if [ "$count" -lt 2 ]; then
    echo "UPGRADE_NEEDED: $proj — $wf has $count opencode step(s), needs 2"
  fi
done
```

---

## Present (✅)

- ✅ Design doc created (this file) (2026-04-20)
- ✅ `otherness-scheduled.yml` in otherness repo: split into two OpenCode steps — Step 7: Vision scan (Step A, `continue-on-error: true`) + Step 8: Run otherness (Step B) (PR #440, 2026-04-20) ⚠️ Stale — referenced file not found
- ✅ `otherness-config-template.yaml`: `schedule.vibe_vision_step: true` field added with comment (PR #456, 2026-04-20)
- ✅ `scripts/validate.sh`: check that scheduled workflow has ≥2 opencode steps when `vibe_vision_step: true` — exits with error if only 1 step found (PR #464, 2026-04-20)
- ✅ `agents/vibe-vision-auto.md` SCAN 2: fixed stale detection false positives — now uses recursive os.walk + exact path matching (handles `.github/workflows/`, `.opencode/command/`) + hostname filter; removed 31 false-positive stale markers from design docs (PR #505, 2026-04-20)

## Future (🔲)

- ✅ Roll out to all managed projects (alibi, kardinal-promoter, kro-ui) — dual-step workflow deployed on all 3 projects (2026-04-20)
- ✅ Vision pressure context injected into Step A workflow prompt for all 3 projects (2026-04-20)
- ✅ `agents/vibe-vision-auto.md` SCAN 5: self-updating pressure prompts — evaluates whether the current workflow vision pressure context is substantially addressed (≥60% of keywords found in last 20 merged PR titles); when staleness threshold reached, injects a 🔲 Future item to trigger a pressure rewrite; agent does NOT directly modify workflow files (docs zone only) (PR #656, 2026-04-20)
- ✅ Cross-project pressure propagation: when otherness identifies a pattern (e.g. "test coverage at edge cases is weak across all 3 projects"), it should update all 3 project pressure prompts — not just its own. The pressure prompt for kro-ui should be informed by what kardinal-promoter learned about user adoption friction, and vice versa. (PR #667, 2026-04-21)

- ✅ 28.1 — Scheduled workflow YAML syntax validated after Step A commit: (1) `scripts/validate.sh` now validates `.github/workflows/otherness-scheduled.yml` YAML syntax using `python3 yaml.safe_load` — exits 1 with clear message on `yaml.YAMLError`; fail-open when PyYAML unavailable; (2) `agents/vibe-vision-auto.md` SCAN 5 now includes a YAML safety gate block: when §37.5 (actual workflow rewrite) is implemented, validates YAML after write and reverts + logs to report issue on error. (PR #853, 2026-04-22)

- 🔲 28.2 — Step B must emit a post-run assertion in the GitHub Actions job summary confirming whether the run met the per-run meaningful-PR contract: the vision.md throughput principle states "every scheduled run must ship at least one merged PR that advances the product vision." But no verification step exists inside the workflow itself. When Step B's SM phase completes, it knows whether a meaningful PR was merged — but this signal is written to `state.json` and the report issue, not to the Actions job summary or the workflow's exit status. The `otherness-scheduled.yml` workflow must add a post-Step-B assertion step: (1) read `state.json` from the session branch for `meaningful_prs`; (2) if `meaningful_prs == 0`: `echo "::warning::Run completed with 0 meaningful PRs — throughput principle not met. Session shipped chores only or no PRs." >> $GITHUB_STEP_SUMMARY`; (3) if `meaningful_prs >= 1`: `echo "✅ Meaningful PRs shipped: N" >> $GITHUB_STEP_SUMMARY`. The assertion step must use `::warning::` (not `::error::`) so the job does not fail — a zero-meaningful-PR run should complete visibly, not abort. Without this assertion, the GitHub Actions job always shows green check regardless of what shipped. A human glancing at the Actions tab cannot tell the difference between a run that shipped 3 feature PRs and a run that shipped 0. The post-run assertion converts the Actions job summary into a per-run delivery signal without requiring the human to open the report issue. ⚠️ Inferred from visibility and reliability lenses: there is no zero-click health signal per-run that confirms meaningful work shipped; the throughput principle exists in vision.md but is never verified in the workflow runner where it is most actionable.

---

## Zone 1 — Obligations

**O1 — Step A runs before Step B in every scheduled execution.**
Vision is always upstream of implementation. The order is not configurable.

**O2 — Step A failure must not block Step B.**
Use `continue-on-error: true` on the Step A workflow step. Step B must always run.

**O3 — Step A writes only to `docs/`. No code changes.**
The vibe-vision agent's `## MODE: VISION` restriction already enforces this. The
design doc must not be changed to remove that restriction.

**O4 — The session branch PR (merged by SM §4g) includes both steps' commits.**
Both steps run on the same checkout (same `opencode/schedule-*` branch). §4g
merges the branch after Step B's SM phase, capturing both vision and code changes.

**O5 — `vibe_vision_step` defaults to `true`.**
Opt-out is possible but not the default. Every new project onboarded via
`/otherness.setup` or `/otherness.onboard` gets Step A enabled automatically.

---

## Zone 2 — Implementer's judgment

- `continue-on-error` granularity: apply at the step level, not the job level.
  A job-level failure would skip Step B entirely, defeating the isolation goal.
- Step A timeout: 30 minutes is sufficient for a vision scan. The full job timeout
  (120 min) covers both steps.
- Whether to add a git pull between Step A and Step B: not needed. Both steps
  run sequentially in the same runner environment with the same `$GITHUB_WORKSPACE`.
  Step A's commits are visible to Step B via the filesystem — no pull needed.

---

## Zone 3 — Scoped out

- Running Step A more frequently than Step B (e.g., vision every 3 hours, run every hour)
- Separate workflow files for vision and run
- Human approval gate between Step A and Step B
