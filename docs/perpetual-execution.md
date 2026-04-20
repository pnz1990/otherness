# Perpetual Execution — How otherness Runs Without You

otherness is designed to run continuously on GitHub Actions infrastructure. You do not
need to keep a session open on your laptop. The system wakes, works, and sleeps on a
schedule — with no human involvement between cycles.

---

## The execution model

Every project using otherness has a scheduled GitHub Actions workflow that fires hourly.
Each run does two things in sequence:

```
┌─────────────────────────────────────────────────────┐
│  Step A — Vision scan (vibe-vision-auto)             │
│  Runs the autonomous vision agent. Reads the         │
│  project's vision pressure context (injected into    │
│  the workflow prompt), finds gaps against that bar,  │
│  and writes new 🔲 Future items to docs/design/.    │
│  continue-on-error: true — Step B always runs.       │
└─────────────────────────────────────────────────────┘
               ↓
┌─────────────────────────────────────────────────────┐
│  Step B — SDLC loop (/otherness.run)                 │
│  Reads the queue. Claims the highest-priority item   │
│  backed by current design doc Future items.          │
│  Implements → QA reviews → CI must pass → merges.   │
│  SM posts health signal. Session branch merged.      │
└─────────────────────────────────────────────────────┘
```

The session branch (the `opencode/schedule-*` branch GitHub Actions runs on) is merged
to main at the end of every batch by SM §4g. All commits from both steps land on main.

---

## What triggers execution

| Trigger | When | Who |
|---|---|---|
| `schedule: cron: "0 * * * *"` | Hourly | GitHub Actions infrastructure |
| `workflow_dispatch` | On demand | Human (you) or `/otherness.status` |

GitHub Actions cron can lag up to 10-15 minutes. This is normal.

---

## The vision pressure prompt

Step A does not run generic scans. It receives a product-specific pressure context
injected directly into the workflow prompt — the same way you would give context after
a slash command in a chat session:

```yaml
prompt: |
  Read and follow $AGENTS_PATH/vibe-vision-auto.md.

  Context for this vision scan:

  The product is not good enough yet. Apply this lens...
  - Is it complete enough for [your specific bar]?
  - Is it stable enough for [your specific users]?
  - Is the UX intuitive enough for [your specific persona]?
  ...
```

This pressure context is what drives meaningful gap identification. Without it, Step A
defaults to mechanical housekeeping (promoting Future items matched by PR titles, flagging
stale file references). With it, Step A produces structured gap analyses with design doc
references that become the next batch's queue.

**The pressure context must evolve.** Once ~60% of the named gaps have been addressed,
the agent rewrites the pressure block automatically (design doc 37 — SCAN 5). The bar
raises itself.

---

## Session lifecycle on GitHub Actions

```
00:00  Cron fires → GitHub Actions queues a run
00:05  Runner provisioned → checks out repo at HEAD of main
00:05  Step A starts: vibe-vision-auto reads vision pressure context
00:12  Step A commits doc updates to session branch
00:12  Step B starts: /otherness.run
         COORD: claims next item from queue
         ENG: implements in feat/* branch
         QA: waits for CI (all checks must pass), reviews, merges
         SM: posts health signal, merges session branch
00:45  Session complete → runner released
```

A typical session with `session_item_limit: 3` runs in 30-50 minutes, well within the
hourly window. The session branch is merged to main before the next cron fires.

---

## What happens if the session takes too long

If a session runs past the 120-minute job timeout (GitHub Actions hard limit), the runner
is killed. The session branch may have open PRs that were not merged. The next session
will find them, check CI, and merge or close them.

If a session consistently approaches the timeout, reduce `session_item_limit` in
`otherness-config.yaml`. A value of 3-5 is recommended for most projects.

---

## Concurrency

The workflow has `concurrency: cancel-in-progress: false`. Sessions must complete.
A cron trigger that arrives while a session is running will queue — not cancel the
running session. This is intentional: a cancelled session wastes all its work (PRs
opened, CI run, but SM not reached, session branch not merged).

---

## The `_state` branch

Session state (`state.json`) lives on a dedicated `_state` branch, never on `main`.
This prevents merge conflicts between parallel sessions and code work. The state
includes the feature queue, session heartbeats, and batch metrics.

---

## Monitoring scheduled runs

You can see all scheduled runs in GitHub Actions:

```
https://github.com/your-org/your-project/actions/workflows/otherness-scheduled.yml
```

Or from the terminal:

```bash
gh run list --repo your-org/your-project \
  --workflow otherness-scheduled.yml --limit 5
```

The report issue (configured via `REPORT_ISSUE` in `AGENTS.md`) receives a health
comment after every batch. Subscribe to it to be notified of `[NEEDS HUMAN]` escalations
and health degradations.

---

## Opting out of perpetual execution

To pause the loop without deleting the workflow:

```bash
# Disable the workflow
gh workflow disable otherness-scheduled.yml --repo your-org/your-project

# Re-enable when ready
gh workflow enable otherness-scheduled.yml --repo your-org/your-project
```

To stop a specific running session:

```bash
gh run cancel RUN_ID --repo your-org/your-project
```
