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

- ✅ 41.3 — validate.sh check [8/8]: ✅ Present items referencing `state.json` fields are spot-checked against local `.otherness/state.json` when present; drift logged as `[DOC-DRIFT]` warnings (informational, not blocking); check skips gracefully when state.json absent (CI); check count updated from [7/7] to [8/8] throughout validate.sh (PR #745, 2026-04-21)

---

## Future (🔲)

- 🔲 41.1 — SM §4f: design doc integrity spot-check every 5 batches: for each `✅ Present` item in `docs/design/*.md` that names a `state.json` field (pattern: `write \`foo\` to state.json` or `` `state.json`: add `foo` field ``), SM §4f checks whether `state.json` actually contains that key. If the key is absent: log `[DOC-DRIFT] ✅ Present item claims state.json.foo exists — not found`. After 3 spot-checks with the same drift: open a `kind/bug priority/high` issue "Design doc integrity: ✅ Present item not reflected in state.json — possible implementation drift." The human should not need to manually discover that a ✅ item isn't running. ⚠️ Inferred from honesty lens: items marked ✅ Present in design docs but corresponding state.json fields absent — system cannot detect its own doc-reality gaps.
- 🔲 41.2 — SM §4f: metrics schema conformance check every batch: count the column separators (`|`) in the last data row of `docs/aide/metrics.md` and compare to the header row. If the column count differs: SM opens a `kind/bug priority/high` issue immediately: "metrics.md schema drift: header has N columns, last data row has M. Columns out of sync — SM §4b is not writing all defined columns." This is a verifiable, automated check that costs <100ms per batch. Running without it means the honesty claims in design doc 33 are unverifiable. ⚠️ Inferred from honesty lens: metrics schema defines 9 columns but batches 90–94 data rows only show 8 — the system does not notice.
- ✅ 41.3 — validate.sh check [8/8]: see ✅ Present section above. (PR #745, 2026-04-21)
- 🔲 41.4 — ENG phase gate: before marking a design doc item ✅ Present, the implementation plan must include a verification step: ENG §2c (implementation checklist) must add: "If this item adds a new `state.json` field: verify the field appears in `_state` branch after implementation. If this item adds a metrics column: verify the last metrics row contains the column. If this item adds an agent instruction section: verify the section header appears in the target agent file." QA §3b adversarial review must check that the ENG checklist included a verification step. A PR that marks ✅ Present without a verification step is rejected by QA. This is the upstream prevention; items 41.1–41.3 are the downstream detection. ⚠️ Inferred from honesty lens: PRs mark ✅ Present at merge time without verifying the feature runs; the QA phase has no gate for this.
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
