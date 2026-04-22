# 41: Design Doc Integrity — Present Markers Must Match Running Code

> Status: Active | Created: 2026-04-21
> Applies to: otherness itself and all managed projects

---

## The problem

The design docs are the authoritative record of what the system does. A `✅ Present`
marker claims a feature is running. But there is currently no mechanism that verifies
this claim. PRs can mark items `✅ Present` without the implementation actually
working — and the system has no way to notice.

Evidence of the gap today (2026-04-21):

- `docs/design/35-quality-of-output-gaps.md`: `SM §4b` session outcome classification
  is marked ✅ Present (PR #655). But `state.json` has no `session_outcome` field.
  The metrics data rows for batches 90–94 show 8 columns, not the 9 the schema defines.
  `vision_prs` and `session_outcome` are defined but not written.

- `docs/design/35-quality-of-output-gaps.md`: `SM §4f` silent-session detection is
  marked ✅ Present (PR #657). But `state.json` has no `silent_session_count` field.
  If the implementation runs, it writes to state. If it doesn't write, it isn't running.

- Multiple ✅ Present items in `docs/design/19-scheduled-execution.md` reference files
  that SCAN 2 has already flagged as not found on disk (`otherness-scheduled.yml`,
  `setup-github-bedrock-key.sh`, etc.).

The pattern: a PR modifies an instruction file and marks the design doc item ✅. If the
instruction file change is wrong or incomplete, the mark is premature. The design doc
becomes a lie — not from bad intent, but from lack of verification.

---

## What "fixed" looks like

The system can answer: **"Is every ✅ Present item actually running?"**

For agent instruction items (SM §4b, COORD §1c, etc.): the agent file contains the
described section. For state-persisted items: `state.json` contains the described key.
For metrics items: the metrics row contains the described column. For file items: the
file exists on disk.

This is not a 100% guarantee — an instruction can be present but wrong. But it closes
the largest gap: items that were never implemented but are marked as done.

---

## Present (✅)

- ✅ 41.1 — SM §4f-integrity: design doc integrity spot-check every 5 SM batches. For each `✅ Present` item in `docs/design/*.md` that names a `state.json` field, SM checks whether the field exists in the actual `_state` branch state.json. Drift logged as `[DOC-DRIFT]`. After 3 consecutive drift findings for the same field: opens a `kind/bug priority/high` issue. Tracks drift counts in `state.json.doc_drift_counts`. Cycle counter in `state.json.sm_batch_count`. (PR #TBD, 2026-04-22)
- ✅ 41.3 — validate.sh check [8/8]: ✅ Present items referencing `state.json` fields are spot-checked against local `.otherness/state.json` when present; drift logged as `[DOC-DRIFT]` warnings (informational, not blocking); check skips gracefully when state.json absent (CI); check count updated from [7/7] to [8/8] throughout validate.sh (PR #745, 2026-04-21)
- ✅ 41.4 — ENG §2f verification gate: before marking 🔲 → ✅ Present, ENG must verify the feature exists via type-specific checks (state.json field, metrics column, or agent section header). QA §3b now also checks for a verification note; PRs flipping 🔲 → ✅ without one are WRONG. Applies only to items touching state.json, metrics, or agent files (docs-only items exempt). (PR #895, 2026-04-22)

---

## Future (🔲)

- ✅ 41.1 — SM §4f-integrity: spot-check every 5 batches. (PR #TBD, 2026-04-22)
- 🔲 41.2 — SM §4f: metrics schema conformance check every batch
- ✅ 41.3 — validate.sh check [8/8]: see ✅ Present section above. (PR #745, 2026-04-21)
- ✅ 41.4 — ENG §2f verification gate + QA §3b check: see ✅ Present section above. (PR #895, 2026-04-22)
- 🔲 41.5 — Periodic full-sweep audit of all ✅ Present items: every 30 batches, PM §5 must run a full audit of all `✅ Present` items across all design docs and categorize each as: (A) verified by test/validate.sh, (B) verified by observable state evidence, (C) verified by PR reference only (weakest), or (D) unverifiable (no PR, no state evidence, no test). Category D items must be individually reviewed and either re-verified, downgraded to `🔲 Future`, or explicitly marked `✅ Present [unverifiable — no observable evidence]`. A design doc corpus where 30%+ of ✅ Present items are category C or D is an audit finding that must be reported on the report issue. ⚠️ Inferred from honesty lens: the simulation exists but predictions are not visibly changing agent behavior; the root cause is that "implemented" features may not actually be running, and there is no periodic audit to surface this.

---

## Zone 1 — Obligations

**O1 — The spot-check is informational, not a blocker.**
Finding a ✅ Present item with no corresponding state.json field does not stop the loop.
It opens an issue. The loop continues. Blocking the loop on a doc-drift finding would
cause more damage than the drift itself.

**O2 — Metrics schema conformance is a hard check.**
If the last metrics row has a different column count than the header, this is a
definitive bug — not a warning. SM opens an issue immediately.

**O3 — The validate.sh check (#41.3) blocks merges to main.**
Unlike the SM spot-check (which is informational), the CI gate can reject a PR that
would introduce a ✅ Present marker for a state.json field that doesn't exist. This
is the right level for a CI gate: prevents regression, does not block the loop.

**O4 — ENG checklist gate (#41.4) applies only to items that touch state.json, metrics, or agent instruction files.**
Not every ✅ Present item needs a state.json verification. Docs-only items, file
creation items, and infra items are not subject to this gate. The gate applies only
when the implementation claim is "this writes data to a file that the agent reads at
runtime."

---

## Zone 2 — Implementer's judgment

- The state.json field extraction heuristic (find `` `state.json`: add `foo` `` patterns)
  will have false positives. Err on the side of over-flagging. A false positive (flagging
  a field that exists) is a wasted log line. A false negative (missing a field that doesn't
  exist) is a silent lie.
- The metrics column count check is O(1) and can run every batch without performance cost.
- The validate.sh check (#41.3) requires `gh api` access to the `_state` branch. This
  means validate.sh can only run in CI (where `GH_TOKEN` is available), not locally
  without auth. Document this constraint in the check output.

---

## Zone 3 — Scoped out

- Full automated test suite for every ✅ Present item (too expensive, too project-specific)
- Retroactive re-verification of all historical ✅ Present items (start from "now forward")
- Automated demotion of ✅ Present to 🔲 Future (human decision required)
