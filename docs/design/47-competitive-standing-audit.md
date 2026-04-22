# 47: Competitive Standing Audit — The System Must Know If It Is Winning

> Status: Active | Created: 2026-04-22
> Applies to: otherness itself
> Source: Vision scan pressure lens 3 (self-improvement)

---

## The problem

AGENTS.md instructs the PM phase to compare otherness against "the community it came from
(Hermes, Multica, Archon)" every batch. PM §5c writes competitive observations as `⚠️ Inferred`
design doc stubs. But the comparison is unstructured — each PM run produces different
observations with no common rubric, no baseline, and no trajectory.

The result: the system cannot answer the question "is otherness ahead of or behind its
comparators, and is the gap widening or closing?" A human reading the report issue sees
individual observations ("spec-kitty is simpler") without any way to track whether
otherness is improving relative to these reference points.

The PM competitive comparison currently produces ad-hoc `⚠️ Inferred` items. It never
produces a comparative score that shows trend over time. This means the "self-improvement
real?" pressure lens cannot be answered by looking at the competitive landscape —
only by looking at internal metrics that the system generates about itself. That is
the definition of a closed feedback loop that cannot detect when the system is
falling behind.

---

## What "fixed" looks like

A human checking system health can open `docs/aide/competitive-standing.md` and read:

```
## 2026-04-22 (batch 101)
| Dimension          | otherness | spec-kitty | delta |
|---|---|---|---|
| Core loop reliability (PRs/run) | 2 | 1 | +1 |
| Self-improvement (skill growth/mo) | 1 | 2 | -1 |
| Onboarding friction (time to first PR) | 1 | 3 | -2 |
| Visibility (30-sec health check) | 2 | 2 | 0 |
| Total | 6/12 | 8/12 | -2 |
```

Over 5 comparison runs, the delta trend tells the human whether otherness is catching up
or falling behind. When the total delta worsens for 3 consecutive comparisons: PM §5 must
open a `[NEEDS HUMAN: competitive-stall]` issue.

---

## Present (✅)

- ✅ PM §5c: competitive gap findings written as `⚠️ Inferred` design doc stubs (PR #307-310, 2026-04-19)

---

## Future (🔲)

- 🔲 47.1 — PM §5c must produce a `docs/aide/competitive-standing.md` file on a fixed rubric: PM §5c currently writes ad-hoc `⚠️ Inferred` stubs. It must additionally maintain a `docs/aide/competitive-standing.md` file with a four-dimension rubric evaluated per comparison run. Four dimensions: (1) **core-loop reliability** — score 0–3: 0=sessions fail silently, 1=sessions run but ship chores, 2=sessions ship features most runs, 3=sessions ship features every run without exception; (2) **self-improvement** — 0=no learning mechanism, 1=manual learning, 2=automated but slow, 3=autonomous rapid skill growth; (3) **onboarding friction** — 0=requires extensive manual setup, 1=requires some manual edits, 2=mostly automated with minor friction, 3=fully automated zero-manual-edit setup; (4) **visibility** — 0=requires local tools to check health, 1=health available but not in 30 seconds, 2=30-second health check exists but incomplete, 3=complete 30-second health check on any device. PM §5c must score otherness AND the highest-scoring known comparator (currently spec-kitty based on doc 45) on all four dimensions each comparison cycle, append a dated row to `competitive-standing.md`, and include a one-line delta summary in the health comment. ⚠️ Inferred from self-improvement lens: the agents are not meaningfully smarter than they were two weeks ago; no artifact tracks whether otherness is ahead of or behind its comparators on the dimensions that matter; the self-improvement claim is currently measured only against internal baselines.

- 🔲 47.2 — Competitive standing delta must trigger behavioral changes in COORD when negative for 3 cycles: when the `competitive-standing.md` delta worsens (total `otherness_score` falls relative to `comparator_score`) for 3 consecutive comparison cycles: PM §5 must: (1) identify which dimension has the largest negative delta; (2) set `next_session_directive: prioritize_<dimension>` in `state.json` where `<dimension>` is the lowest-delta area (e.g. `prioritize_onboarding`, `prioritize_visibility`); (3) open a `kind/enhancement priority/high` issue: "[COMPETITIVE GAP] otherness is falling behind on [dimension] — 3 consecutive comparisons show negative delta. COORD will prioritize [dimension]-related queue items for the next 5 batches." COORD §1b-preflight must read `next_session_directive` and preferentially claim issues tagged with the relevant area. Without this behavioral change, a worsening competitive position is detected but not acted upon — the observation loop is closed but the correction loop is not. ⚠️ Inferred from honesty lens: metrics are collected but not acted on; the competitive standing comparison is no different from any other metric that observes but does not change behavior.

- 🔲 47.3 — Comparator list must be version-controlled and updatable without code changes: the current comparator set (Hermes, Multica, Archon) was specified in AGENTS.md. As the landscape evolves, new comparators emerge (new autonomous coding agents, new CI/CD loop systems) and old ones become irrelevant. `otherness-config.yaml` must accept an optional `pm.comparators:` list — a list of repo slugs or product names to include in competitive comparisons. When `pm.comparators` is absent: PM §5c uses the default list from AGENTS.md. When present: it uses the config list. This allows the human operator to update the comparison set without a code change. PM §5c must log which comparators were evaluated in each `competitive-standing.md` row so that the comparison is auditable even as the list changes. ⚠️ Inferred from self-improvement lens: the system compares against a fixed set of comparators defined in AGENTS.md — this list cannot be updated without a file edit; a config-driven comparator list makes the competitive analysis responsive to the changing landscape.

- 🔲 47.4 — Competitive standing score must appear in every SM health comment once `competitive-standing.md` exists: once PM §5c has produced a `competitive-standing.md` file with ≥1 row, SM §4f must include a one-line competitive summary in the health comment: "vs. [top comparator]: [total otherness score]/12 vs. [comparator score]/12 (Δ [delta], [N] cycles [improving/flat/declining])". This gives the human visibility into competitive position with zero additional clicks. Without this line, `competitive-standing.md` is a file nobody checks unless they specifically navigate to it. The health comment is read every batch; competitive standing should be surfaced there. ⚠️ Inferred from visibility lens: a human looking at GitHub right now cannot quickly tell whether the system is moving toward the vision or spinning in circles; competitive position is a key indicator of strategic health; surfacing it in the health comment costs one line and provides the external benchmark the internal health signal cannot provide.

---

## Zone 1 — Obligations

**O1 — Competitive standing is informational, not a gate.**
The competitive score never blocks COORD from claiming items. It influences priority
via `next_session_directive` only when 3 consecutive cycles show worsening delta.

**O2 — Scores are honest assessments, not vanity metrics.**
PM §5c must score otherness critically — the same lens it uses for comparators.
If onboarding requires manual editing, the score is 1, not 3. Inflated self-scoring
defeats the purpose of the comparison.

**O3 — The rubric is fixed per doc version.**
The four dimensions and their 0–3 scale are defined here. PM §5c must not change
the rubric mid-comparison. If the rubric needs updating, a new version of this doc
must be written and the historical rows explicitly migrated.

**O4 — Fail-open on comparator evaluation.**
If PM §5c cannot gather sufficient information about a comparator (private repo,
no public activity), score that comparator as "unknown" and note it. Do not skip
the comparison entirely — an unknown comparator is information.

---

## Zone 2 — Implementer's judgment

- The highest-signal comparator currently is spec-kitty (doc 45). PM §5c should use
  GitHub's public repo API to check star count, recent PRs, and README for the
  four-dimension scoring. No web scraping required.
- `competitive-standing.md` format: simple markdown table with one dated row per
  comparison cycle. Append-only. The file belongs in `docs/aide/` (written by agents,
  readable by humans) not `docs/design/` (design intent).
- Comparison cycle: every 10 PM cycles (to align with simulation calibration cadence).

---

## Zone 3 — Scoped out

- Automated scraping of comparator feature lists
- Real-time comparator tracking (10-cycle cadence is sufficient)
- Numerical models for competitive advantage scoring
