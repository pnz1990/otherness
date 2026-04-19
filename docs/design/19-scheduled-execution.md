# 19: Scheduled Execution — The Loop That Never Needs You to Press Play

> Status: Active | Created: 2026-04-19
> Applies to: otherness itself and all managed projects

---

## The problem this solves

When the conversation ends, the loop stops. A local persistent process solves nothing
— it dies when the machine sleeps, the terminal closes, or the user logs out.

The loop is only genuinely eternal if it runs on infrastructure that does not depend
on a human-initiated session. That infrastructure is GitHub Actions with a schedule
trigger.

---

## The mechanism

OpenCode has a native GitHub Actions integration (`anomalyco/opencode/github@latest`)
that supports `schedule` events. A cron workflow checks out the repo, runs OpenCode
with the `/otherness.run` prompt, and exits. The next cron trigger does the same.

The loop runs every N hours. No human required.

```yaml
# .github/workflows/otherness-scheduled.yml
name: otherness scheduled run

on:
  schedule:
    - cron: "0 */6 * * *"  # every 6 hours
  workflow_dispatch:         # manual trigger for testing

jobs:
  otherness:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: write
      pull-requests: write
      issues: write
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          persist-credentials: false

      - name: Self-update otherness agent files
        run: git clone --quiet https://github.com/pnz1990/otherness.git ~/.otherness

      - name: Run otherness
        uses: anomalyco/opencode/github@latest
        env:
          ANTHROPIC_API_KEY: ${{ secrets.ANTHROPIC_API_KEY }}
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

---

## What changes when this runs on a schedule vs a human session

**Same:** The agent loop is identical. It reads state.json, claims items, implements,
runs QA, merges, reports health signal. Every phase runs the same way.

**Different:** The session is bounded. A GitHub Actions runner has a 6-hour job
timeout. The agent loop should detect this and write a clean handoff to `_state`
before the runner terminates. Batches complete fully; the runner exits; the next
schedule trigger picks up where the handoff says.

This is already handled: the SM phase writes a session handoff to `_state` after every
batch. The next session reads it and resumes cleanly. The distributed lock protocol
(`feat/<item>` branch) prevents two parallel runners from claiming the same item.

---

## The cadence

| Cadence | What it means |
|---|---|
| Every 6 hours | 4 runs/day. Each run completes 1–3 batches depending on item complexity. |
| `workflow_dispatch` | Manual trigger for testing or immediate execution. |
| On push to main | Not triggered on push — the loop is autonomous, not CI. |

6 hours is conservative. A project with a healthy queue can run every 4 hours.
A project in standby (empty queue, autonomous vision synthesis waiting) can run every
12 hours.

The cadence is configurable in `otherness-config.yaml`:

```yaml
schedule:
  cron: "0 */6 * * *"   # default: every 6 hours
  model: amazon-bedrock/global.anthropic.claude-sonnet-4-6
```

---

## What this unlocks

When this workflow is deployed:

1. Human pushes vision via `/otherness.vibe-vision` → design doc stubs land on main
2. Next scheduled run picks up the new Future items → COORD queues them
3. Batches run → items ship → health signal GREEN
4. Queue empties → SM §4h fires → autonomous-vision.md synthesizes new items
5. Next scheduled run picks up synthesized items → batches run
6. The loop never stops

The human receives batch reports on the report issue. They can add vision any time.
They redirect when needed. But they do not press play.

---

## Security model

The workflow uses:
- `ANTHROPIC_API_KEY` (or equivalent) as a GitHub Actions secret
- `GITHUB_TOKEN` (built-in) for repo operations — no PAT needed
- `contents: write` + `pull-requests: write` + `issues: write` permissions

The agent runs inside GitHub's own infrastructure. It cannot access secrets not
explicitly granted to the workflow. It cannot write to other repos. It cannot
escalate permissions beyond what the workflow grants.

---

## Present (✅)

*(Not yet implemented.)*

## Future (🔲)

- 🔲 `.github/workflows/otherness-scheduled.yml` — cron workflow using `anomalyco/opencode/github@latest` with the `/otherness.run` prompt
- 🔲 `otherness-config.yaml`: `schedule.cron` and `schedule.model` fields for per-project cadence
- 🔲 `otherness-config-template.yaml`: `schedule` section added
- 🔲 `scripts/validate.sh`: check that scheduled workflow file exists if `schedule.cron` is set in config
- 🔲 `/otherness.setup` and `/otherness.onboard`: add step to deploy the scheduled workflow during project setup

---

## Zone 1 — Obligations

**O1 — The scheduled workflow uses `anomalyco/opencode/github@latest`.**
Not a custom bash script. The OpenCode GitHub Action is the correct primitive — it
handles authentication, checkout, and agent execution. The prompt is the same
`standalone.md` invocation used in manual sessions.

**O2 — The workflow grants `contents: write`, `pull-requests: write`, `issues: write`.**
The agent needs to create branches, merge PRs, and post comments. These permissions
are required. They are scoped to the repository only.

**O3 — The `ANTHROPIC_API_KEY` (or model provider key) is stored as a GitHub Actions secret.**
Never in the workflow file. Never in otherness-config.yaml. The secret name is
documented in otherness-config.yaml under `schedule.api_key_secret`.

**O4 — The session handoff in `_state` is written before each runner terminates.**
The SM phase already writes a handoff. This obligation is already met by existing
code. No new implementation needed for this constraint.

**O5 — `workflow_dispatch` is always included alongside the schedule trigger.**
This allows manual testing and on-demand runs without waiting for the next cron tick.

---

## Zone 2 — Implementer's judgment

- Model selection: the same model as the manual session. Configured in
  `otherness-config.yaml` under `schedule.model`. Falls back to the default
  model if not set.
- Whether to use `persist-credentials: false`: yes — the agent manages its own git
  operations through the GITHUB_TOKEN. Persisting credentials from checkout would
  conflict.
- Whether to run on push to main: no. The scheduled loop is autonomous. Push-triggered
  runs would create double-execution when the agent itself merges PRs.
- Runner type: `ubuntu-latest`. The agent only needs git, gh CLI, and python3 — all
  available on ubuntu-latest.

---

## Zone 3 — Scoped out

- Multi-repo orchestration from a single workflow (each project has its own workflow)
- Parallel runners (the distributed lock already handles this, but multiple runners
  consuming tokens unnecessarily is wasteful — single runner per cron tick is correct)
- Cost management / token budgeting (future: add a token-spent counter to state.json)
