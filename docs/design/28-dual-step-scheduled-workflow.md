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
- ✅ `otherness-scheduled.yml` in otherness repo: split into two OpenCode steps — Step 7: Vision scan (Step A, `continue-on-error: true`) + Step 8: Run otherness (Step B) (PR #440, 2026-04-20)
- ✅ `otherness-config-template.yaml`: `schedule.vibe_vision_step: true` field added with comment (PR #456, 2026-04-20)
- ✅ `scripts/validate.sh`: check that scheduled workflow has ≥2 opencode steps when `vibe_vision_step: true` — exits with error if only 1 step found (PR #464, 2026-04-20)

## Future (🔲)

- 🔲 Roll out to all managed projects (alibi, kardinal-promoter, kro-ui)

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
