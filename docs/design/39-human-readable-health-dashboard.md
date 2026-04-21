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
- 🔲 39.11 — All 39.x items have been `🔲 Future` for 90+ batches — COORD must prioritise them as a block: the visibility layer (39.1–39.10) has been fully specified across this design doc for over 90 batches. None are `✅ Present`. This means the system has run for 90+ batches without shipping any of the visibility improvements that the design doc identifies as the highest-impact gap for human confidence. This is a systemic prioritisation failure, not a specification gap. COORD §1c must: (1) detect when a design doc has ≥5 `🔲 Future` items that have been open (as GitHub issues) for >30 days without any being claimed; (2) when detected: create a `kind/enhancement priority/critical` issue: "[Visibility Debt] Design doc 39 has N unshipped items open for >30d — treating as technical debt sprint"; (3) assign `priority/critical` to all open 39.x issues; (4) set `next_session_directive: prioritize_doc_39` in `state.json`. The human wrote these items expecting them to ship. When they don't ship for 90 batches, the system must self-diagnose and self-escalate — not wait for the human to notice the staleness. ⚠️ Inferred from visibility lens: the entire visibility layer has been specified but none of it has shipped; the system does not self-detect long-running specification-without-implementation gaps.
- 🔲 39.12 — Visibility PRs must be verifiable: when a PR claims to implement a 39.x item (e.g. "feat(sm): structured health table in report issue"), QA must verify the claim by actually inspecting the report issue body. QA §3a currently checks code diffs and CI. It does NOT check GitHub artifacts (issue bodies, PR bodies, Actions summaries) to confirm that claimed visibility improvements are actually visible. QA must add a 39.x verification step: for any PR referencing `39.` in its title or body, QA must (1) `gh issue view $REPORT_ISSUE --json body`, (2) verify the issue body contains a markdown table with the expected columns, (3) fail the QA review if the table is absent. Without this check, a PR can claim to implement 39.1 by touching SM §4f code without the health table actually appearing in the report issue — the claim is unverified at merge time. ⚠️ Inferred from visibility lens: the visibility layer has been specified but no mechanism verifies that implementations are actually visible to a human visiting the GitHub UI.
- 🔲 39.13 — Health comment must name the most important PR shipped this session — not just a count: the proposed health table (39.1) includes a "Last PR" row, but the value populated there is the most-recent-by-time PR, not the highest-value PR. A session that ships 8 chore PRs and 1 feat PR will show the last chore in "Last PR" if it was committed after the feat. The human reads "Last PR: chore(sm): metrics update" and concludes nothing meaningful shipped. SM §4f must: (1) compute `best_pr_this_session` — the merged PR with the highest "vision value" (feat > fix > chore, tiebreak by design-doc-referenced > not); (2) use `best_pr_this_session.title` as the "Top PR" row in the health table, not the latest-by-time PR; (3) if `meaningful_prs == 0`: display "Top PR: none — chore-only session" in AMBER. This one field change converts the health table from "last thing committed" to "most important thing shipped" — which is what the human actually wants to know. The current design shows recency; this change shows value. ⚠️ Inferred from visibility lens: a human looking at GitHub right now cannot quickly tell what the system shipped today; the "Last PR" field in the proposed table will show a chore if the last commit was a chore, hiding the real signal about whether the system is moving toward the vision or spinning in circles.
- 🔲 39.14 — COORD must have a concrete label-based mechanism to identify and elevate visibility issues: items 39.9 and 39.11 specify that COORD must prioritise doc-39 issues — but neither specifies how COORD identifies them. The mechanism must not depend on issue number ranges (fragile) or body text search (slow and error-prone). The fix: when COORD §1c creates a GitHub issue from a 39.x design doc Future item, it must attach a `area/visibility` label. COORD §1e claim-sort must give `area/visibility + kind/enhancement` issues a priority boost equal to `priority/high` regardless of the `priority/` label set on the issue. `scripts/validate.sh` must verify that the `area/visibility` label is in the project's label taxonomy (a missing label silently falls back to no special treatment). Additionally: SM §4b must track `visibility_prs_shipped` as a metric — PRs that close an issue labeled `area/visibility`. This single label makes the visibility debt trackable, discoverable, and elevatable without hardcoded doc-number references. ⚠️ Inferred from visibility lens: items 39.9 and 39.11 specify COORD priority elevation but provide no concrete detection mechanism — without a label or tag, COORD cannot distinguish visibility issues from other kind/enhancement issues in the queue.


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
