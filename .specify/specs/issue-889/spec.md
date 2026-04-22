# Spec: PM competitive rubric artifact (issue-889)

## Design reference
- **Design doc**: `docs/design/17-vision-evolution-cadence.md`
- **Section**: `§ Future`
- **Implements**: PM competitive comparison must produce a verifiable rubric artifact — moves 🔲 → ✅

---

## Zone 1 — Obligations (falsifiable)

**O1** — `docs/aide/competitive-standing.md` must exist after the first PM §5c cycle that runs since this PR merges.
- Violation: the file does not exist after PM §5c runs.

**O2** — The file must contain a schema header row: `| Date | Batch | Comparator | reliability | self-improvement | onboarding | visibility | delta |`
- Violation: the header is absent or uses different column names.

**O3** — PM §5c must append exactly one dated row per 10-batch comparison cycle, not on every run.
- Violation: multiple rows appended in a single 10-batch period for the same comparator.

**O4** — Each row must contain scores for all four rubric dimensions: `reliability`, `self-improvement`, `onboarding`, `visibility` — each as `otherness_score/comparator_score` (e.g. `2/1`).
- Violation: any dimension column is empty or missing.

**O5** — SM §4b health comment must include a one-line competitive delta string formatted: `vs. <comparator>: <delta> (last checked: N batches ago)` when `competitive-standing.md` has at least one data row.
- Violation: the health comment does not include the competitive delta when data exists.

**O6** — When `competitive-standing.md` does not exist or has no data rows, SM §4b must omit the competitive delta line silently (no error output).
- Violation: SM §4b fails or posts an error when the file is absent.

**O7** — `validate.sh` and `test.sh` must not fail due to this change.
- Violation: CI red after this PR.

---

## Zone 2 — Implementer's judgment

- Which comparator to score first (spec-kitty / Hermes / Multica / Archon) — choose based on visibility in AGENTS.md; Hermes + spec-kitty as primary.
- Score values for the initial bootstrap row — use publicly observable evidence from GitHub activity.
- Whether to use a Python helper or inline bash in pm.md for the row append.

---

## Zone 3 — Scoped out

- Real-time web scraping of competitor activity (use GitHub API / last-commit evidence only).
- Automated score interpretation / AI judgment in the append block (scores are static per cycle).
- SM §4f changes (only §4b is in scope per the issue).
