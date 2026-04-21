# 39: Human-Readable Health Dashboard — 30-Second System Status

> Status: Active | Created: 2026-04-20
> Applies to: otherness itself and all managed projects

---

## The problem

A human who opens the GitHub repo right now cannot quickly answer three questions:

1. Is the system healthy? (running, shipping, not stalled)
2. What did it ship today?
3. Is it moving toward the vision or circling in chores?

The data exists. `docs/aide/progress.md`, the report issue, `_state` branch commits,
and open PRs together contain the answers. But assembling them requires:
- opening the report issue (verbose, technical, multi-comment thread)
- reading `docs/aide/progress.md` (manually updated, often stale)
- running `/otherness.status` (requires local setup, not visible on GitHub)
- scanning open PRs (unlabelled, mixed signal)

The result: the human defaults to "I'll check later" and loses confidence in the
system. The system may be healthy and shipping but *look* idle to a casual observer.

This is not a tooling problem — it is a communication problem. The system must make
its health state legible without requiring any human tool invocation.

---

## What "fixed" looks like

A human opens the repo. In the top comment of the report issue (or the `docs/aide/progress.md`
file, pinned), they see a table like this — updated every batch, readable in 30 seconds:

```
## otherness health — 2026-04-20

| Signal        | Value        | Trend  |
|---|---|---|
| Health        | 🟢 GREEN     | stable |
| Batch         | #93          | +1     |
| Shipped today | 3 PRs        | ↑      |
| Vision PRs    | 2 / 3 (67%)  | good   |
| Queue         | 40 todo      | full   |
| Last PR       | feat(sm): §4f silent-session detection |
| Sim calibrated| 0 days ago   | fresh  |
| Needs human   | 0 open       | clean  |
```

This is the single-page health summary. It replaces the 20-line health comment with
a scannable table. It is the answer to "is it working?" in one glance.

---

## Present (✅)

*(Nothing shipped yet.)*

---

## Future (🔲)

- 🔲 39.1 — SM §4f: replace verbose health comment with structured table: the current health comment is a multi-line prose block (Health: GREEN, batch count, recent PRs). Replace it with a markdown table: rows for Health signal, Batch number, PRs merged today, Vision PR ratio, Queue depth, Last PR title, Sim calibrated age, Needs-human open count. The table must fit in 10 lines and be readable without context. Cap history: the report issue shows only the last table (edit the previous comment, don't add new ones). ⚠️ Inferred from visibility lens: report issue comments too verbose and technical; human cannot tell system health at a glance.
- 🔲 39.2 — SM §4f: edit the top-level report issue body with the latest health table: the report issue body (not a comment) serves as the persistent "current state" display. SM §4f must `gh issue edit $REPORT_ISSUE --body "$(cat <<'EOF'\n...\nEOF\n)"` to update the issue body with the latest health table every batch. A human clicking the report issue link sees current state immediately, without scrolling through comments. This is the "single page" — everything needed to assess health in one view.
- 🔲 39.3 — `docs/aide/progress.md` auto-sync with health table: the health table written by SM §4f to the report issue must also be written to `docs/aide/progress.md` in the same batch. The file is the human-readable record; the issue comment is the live signal. They must always agree. SM §4f writes one, commits it; the issue body is updated in the same step. No drift between the two.
- 🔲 39.4 — `/otherness.status` renders the same health table: the command currently outputs a custom format. It must render the exact same table that SM §4f writes to the report issue. Consistency: a human who runs `/otherness.status` sees the same signal they'd see opening the report issue. No two formats for the same data. ⚠️ Inferred from visibility lens: `/otherness.status` output format not standardised against the SM health comment.
- 🔲 39.5 — `_state` branch commit message includes health summary: every `_state` branch push by SM §4g must use the commit message format `"sm: batch N — GREEN | 3 PRs | 40 todo"`. This makes the `_state` branch commit history a lightweight timeline readable from `gh api` or the GitHub UI without opening any issue. Operators monitoring multiple projects can use `gh api repos/$REPO/commits?sha=_state&per_page=5` to get a 5-line health history in one API call. ⚠️ Inferred from visibility lens: no clean single-page health dashboard; _state branch not used as a timeline.
- 🔲 39.6 — Fleet health summary in `/otherness.status --fleet`: for operators running otherness on multiple projects, a single table showing all managed projects' health signals is needed. Each row: repo, health signal, batch number, last PR title, days since last activity. Data source: `_state` branch of each managed project. `/otherness.status --fleet` must render this table. Currently `/otherness.status` is single-project only; fleet visibility requires cross-repo `_state` reads. ⚠️ Inferred from visibility lens: operator managing multiple projects cannot see fleet health without opening each repo individually.
- 🔲 39.7 — Repo main page shows loop-alive signal without any clicks: a human landing on the GitHub repo root page currently sees no indication that the autonomous loop is alive. The README, repo description, and pinned files do not reflect real-time system state. The fix: SM §4g must update `docs/aide/progress.md` with a one-line status badge format compatible with GitHub's README rendering — e.g. a plain-text "Last batch: 2026-04-21 | Health: 🟢 | PRs today: 3" at the top of `progress.md`. Additionally, SM §4g must update the repo's GitHub description via `gh api repos/$REPO --method PATCH --field description="otherness | batch 94 | 🟢 GREEN | last PR: feat(sm)..."` (≤120 chars). A human arriving at the repo main page sees in the description field that the system ran recently and is healthy — without opening any file. ⚠️ Inferred from visibility lens: the system is healthy and shipping but looks idle to a casual observer; there is no zero-click health signal on the repo main page.
- 🔲 39.8 — Design doc Present-vs-reality auditor: SM §4f must verify that items marked ✅ Present in design docs actually exist in the agent instruction files. For each `✅ Present` item that names a specific agent instruction (e.g. "SM §4b: session outcome classification"), SM must check whether the agent file contains the described section header or instruction pattern. If not found: flag the item as `⚠️ Drift — marked Present but not found in agent files`. This is the minimum guard against the failure mode where a PR "implements" a design doc item by marking it ✅ without adding the actual agent instruction. The design doc says the loop is honest; the loop must prove it by verifying its own claims. ⚠️ Inferred from honesty lens: items are marked ✅ Present in design docs (e.g. session outcome classification PR #655) but the state.json and metrics rows show the implementation may not be running — the system has no mechanism to detect this gap between claim and reality.
- 🔲 39.9 — Health dashboard must be complete before the loop is considered "moving toward the vision": all seven 39.x items (39.1–39.7) are `🔲 Future` — none are `✅ Present`. A human opening the report issue today sees verbose unstructured comments, not a health table. A human visiting the repo main page sees no loop-alive signal. The `/otherness.status` command exists but outputs a non-standard format. The entire visibility layer is unimplemented while the loop has been running for 90+ batches. This is the highest-impact gap for human confidence in the system. COORD §1c must give `kind/enhancement` issues tagged `area/docs,area/tooling` that close 39.1–39.4 elevated priority over other queue items until ≥3 of them are `✅ Present`. The loop cannot be considered "moving toward the vision" while the operator cannot read its health at a glance. SM §4b must track a `visibility_prs` metric (PRs that close 39.x issues) and flag when this count is 0 for 5 consecutive batches while 39.x items remain open. ⚠️ Inferred from visibility lens: the visibility layer has been fully specified but none of it has shipped; after 90+ batches the human still cannot tell system health without manual investigation.
- 🔲 39.10 — SM §4f: write health summary to `$GITHUB_STEP_SUMMARY` on every batch: the Actions job summary page is visible to anyone with repo access, requires no local tools, and is indexed per-run. SM §4f must append the health table to `$GITHUB_STEP_SUMMARY` using `echo "..." >> $GITHUB_STEP_SUMMARY`. Format: the same markdown table as 39.1 (health, batch, PRs merged, vision ratio, queue depth, last PR, sim calibrated age, needs-human count). A human checking the Actions tab sees the health summary for that run directly in the job summary — no issue, no command, no file to open. This is the lowest-friction visibility mechanism available on GitHub and it requires exactly one `echo` line in the workflow. The fact that it has been omitted for 90+ batches while the visibility gap is called out as critical is itself an indicator of the gap. Cost: trivial. Value: a human checking "did the last run do anything useful?" gets an answer in 5 seconds. ⚠️ Inferred from visibility lens: zero-click health visibility from the Actions tab is not implemented; the most accessible GitHub visibility surface (job summary) is unused.

---

## Zone 1 — Obligations

**O1 — The health table is updated every batch without exception.**
SM §4f is the only writer. The table must reflect the batch that just completed —
not the previous batch, not a cached value. Stale health data is worse than no data.

**O2 — The table uses emoji sparingly and consistently.**
Green circle = GREEN, yellow = AMBER, red = RED. No other emoji. The table must be
readable in terminal output (ASCII fallback) and GitHub markdown. Do not use emoji
that render incorrectly in terminal.

**O3 — The report issue body is the authoritative health display.**
PR comments, commit messages, and `/otherness.status` are derived signals. When any
of them disagree with the report issue body, the report issue body wins. SM §4f updates
the report issue body as the primary write, then derives other outputs from it.

**O4 — The health table never includes personally identifiable information.**
No usernames, no API keys, no internal URLs. The table is a public-facing signal.

---

## Zone 2 — Implementer's judgment

- The report issue body edit: `gh issue edit $REPORT_ISSUE --repo $REPO --body "..."` is the
  correct command. The body should include the table plus a one-line footer: "Updated by
  SM §4f — batch $N — $DATE". This footer is the timestamp.
- `/otherness.status` output: render the same table to stdout, optionally followed by the
  last 3 lines of the health comment thread for context.
- `_state` commit message format: keep it to <72 chars. "sm: batch N — GREEN | M PRs | K todo"
  is 40–50 chars and fits. Do not include PR titles (too long, breaks the format).
- Fleet mode: read `monitor.projects` from `otherness-config.yaml` for the project list.
  Each project's `_state` branch is readable without authentication on public repos.

---

## Zone 3 — Scoped out

- External dashboard (Grafana, Datadog, custom web UI) — GitHub UI is sufficient for now
- Real-time streaming health (batch granularity is the right frequency)
- Slack/email notifications (out of scope until user request)
- Mobile-optimised health view
