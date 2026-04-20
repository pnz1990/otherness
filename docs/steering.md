# Steering — How to Monitor and Direct a Running System

otherness runs on its own. Your job is to seed the initial vision, observe what ships,
and occasionally redirect when the system drifts. This guide covers how to do that from
a local session.

---

## The human's role in the steady state

Once a project is onboarded and the scheduled workflow is running, your interaction pattern is:

```
1. Read the batch reports  (minutes per week)
2. Run /otherness.vibe-vision when you have new direction  (30-60 min, whenever needed)
3. Unblock [NEEDS HUMAN] issues  (rare — minutes each)
4. Monitor the fleet health signal  (/otherness.status --fleet)
```

That's it. You do not review PRs. You do not approve merges. You do not manage the queue.
The system handles all of that.

---

## Checking what's happening right now

Open a local session and run:

```bash
/otherness.status
```

This reads the `_state` branch, open issues, recent CI runs, and the report issue, then
prints a health summary. Add `--fleet` to see all projects you own that are running otherness.

You can also check directly from the terminal without a session:

```bash
# Latest session run
gh run list --repo your-org/your-project \
  --workflow otherness-scheduled.yml --limit 5

# What's in the queue
gh issue list --repo your-org/your-project \
  --state open --label "your-project-label"

# Open PRs (feature work in progress)
gh pr list --repo your-org/your-project --state open

# Blocking issues
gh issue list --repo your-org/your-project \
  --state open --label "needs-human"

# Latest health signal
gh api repos/your-org/your-project/issues/REPORT_ISSUE/comments \
  --jq 'last | .body' 
```

---

## Reading the batch reports

The report issue receives a comment after every batch:

```
[🔄 SDM | sess-abc123 | otherness@abc1234] Batch 47.
Health: GREEN | Vision PRs this run: 2 | Queue: 8 todo 1 in_review | Action: Active
```

**Health: GREEN** — CI passing, no `[NEEDS HUMAN]` issues, ≥1 vision-backed PR shipped.

**Health: AMBER** — something needs attention. Common causes:
- `[NEEDS HUMAN]` issue open (merge blocked, token invalid, judgment call required)
- CI red on main
- 0 vision-backed PRs this session (loop may have drifted to housekeeping)

**Health: RED** — CI red for >24h or a critical regression.

When you see AMBER or RED, open a local session and investigate:

```bash
/otherness.run
# The SM phase will triage the issue automatically on the next run
# Or you can run vibe-vision to redirect:
/otherness.vibe-vision
```

---

## Giving new direction — the vision session

When you have new product direction, run a vision session from your project directory:

```bash
cd your-project
/otherness.vibe-vision
```

The agent enters a dialogue with you. You describe what you want the product to become —
in plain language, without worrying about tasks or implementation. The agent reflects back
what it heard, asks one clarifying question if needed, then writes design doc stubs with
`🔲 Future` items and updates `docs/aide/roadmap.md`.

Those design doc items become the queue. The next scheduled session picks them up.

You do not need to write tasks, open issues, or edit specs. The cascade is automatic:

```
Your words → vision session → docs/design/N-area.md → 🔲 Future items
                                                      → COORD reads them
                                                      → issues created
                                                      → ENG implements
                                                      → QA reviews
                                                      → merged
```

### When to run a vision session

- When the health signal is persistently AMBER and the queue looks stale
- When a major product direction changes
- When you want to raise the bar on something specific (security, UX, performance)
- About once per week for an actively developing project; less often for stable ones

You do not need to run it on a schedule. The autonomous vision step (Step A) generates
inferred items continuously. A human vision session overrides and directs — it is the
highest-fidelity input to the system.

---

## Monitoring multiple projects (fleet view)

If you have several projects running otherness, use `/otherness.status --fleet` or check
them directly:

```bash
# From otherness config — list all monitored projects
python3 -c "
import re
in_monitor = in_projects = False
for line in open('otherness-config.yaml'):
    if re.match(r'^monitor:', line): in_monitor = True
    if in_monitor and re.match(r'\s+projects:', line): in_projects = True
    if in_projects:
        m = re.match(r'\s+- (.+)', line)
        if m: print(m.group(1).strip())
" ~/.otherness/otherness-config.yaml

# Check all at once
for repo in $(python3 -c "..." ); do
  echo "=== $repo ==="
  gh run list --repo $repo --workflow otherness-scheduled.yml --limit 1 \
    --json status,conclusion,createdAt \
    --jq '.[0] | "\(.createdAt[:16]) \(.status) \(.conclusion // "active")"'
  gh issue list --repo $repo --state open --label "needs-human" \
    --json number,title --jq 'length | "  needs-human: \(.)"'
done
```

The SM cross-project monitoring phase (SM §4a) also watches monitored projects and opens
issues on itself when it detects problems on a peer project.

---

## Unblocking `[NEEDS HUMAN]` issues

These are rare. They appear when the agent has attempted autonomous resolution and failed.
Legitimate cases:

1. **Token invalid or expired** — rotate the `GH_TOKEN` secret or regenerate the App token.
2. **Token lacks admin rights** — branch protection cannot be cleared; the agent cannot merge.
   Go to the repo Settings → Branches → edit the main branch rule → allow administrators to bypass.
3. **Genuine judgment call** — the agent hit a design conflict it cannot resolve autonomously.
   Read the issue, make a decision, post a comment with your decision, then close the issue.

After addressing a `[NEEDS HUMAN]` issue, close it. The next scheduled session will resume.

---

## Manual triggers

To trigger a run immediately without waiting for the next hourly cron:

```bash
gh workflow run otherness-scheduled.yml --repo your-org/your-project
```

Useful when:
- You just merged a vision session PR and want the queue to update now
- You closed a `[NEEDS HUMAN]` issue and want the session to resume
- You want to verify a fix is working

---

## Adjusting throughput

The `session_item_limit` in `otherness-config.yaml` controls how many items each session
processes before SM/PM phases run and the session ends.

```yaml
# In otherness-config.yaml (in your project root)
session_item_limit: 3   # 3 items ≈ 25-35 min session, safe for hourly cron
session_item_limit: 5   # 5 items ≈ 45-55 min session, still fits hourly
session_item_limit: 10  # 10 items ≈ 90+ min — risks session timeout and cancellation
```

Lower is safer. The system runs every hour regardless — total throughput is
`session_item_limit × runs_per_day`. Three items per session at hourly cadence = 72 items
per day, which is far more than any team ships manually.

---

## What not to do

**Do not open PRs manually to bypass the queue.** The agent may close them, create conflicting
branches, or get confused by the state. If you want something done urgently, add a
`priority/critical` issue and the next session will claim it first.

**Do not edit `docs/aide/vision.md` directly.** Run `/otherness.vibe-vision` instead. The
vision session validates and structures your intent before writing it — direct edits often
produce format errors that confuse COORD.

**Do not run `/otherness.run` while a scheduled session is active.** The distributed lock
(branch-push concurrency) will handle this, but it creates confusion in the state. If you
want to steer, use `/otherness.vibe-vision` (vision layer only) which does not touch the queue.

**Do not change `session_item_limit` to 0 to "pause" the loop.** Use `gh workflow disable`
instead. A limit of 0 causes the session to run SM/PM but skip ENG, which produces
spurious health signals.
