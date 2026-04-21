# Spec: PM §5n — Dual Improvement Rate Reporting

**Item**: issue-771
**Date**: 2026-04-21

## Design reference
- **Design doc**: `docs/design/16-journey-2-reference-project.md`
- **Section**: `§ Future`
- **Implements**: PM §5: otherness self-improvement rate vs. managed project improvement rate (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — PM computes `self_feat_prs` per batch.**
PM §5n must count feat/fix/refactor PRs merged to the otherness repo in the last 7 days.
Violation: the metric is absent or counts chore/session PRs.

**O2 — PM computes `managed_feat_prs` per batch.**
PM §5n must count feat/fix/refactor PRs merged to non-otherness monitor.projects in the last 7 days.
Violation: only otherness-self PRs are counted; managed projects are not checked.

**O3 — SM §4f health comment includes both values.**
The batch health comment posted to the report issue must include both `self_feat_prs` and `managed_feat_prs`.
Violation: health comment only shows one rate or neither.

**O4 — `managed_feat_stall_count` is persisted in state.json.**
Each batch where `managed_feat_prs == 0` while `self_feat_prs > 0` increments a counter in state.json.
Each batch where `managed_feat_prs > 0` resets it to 0.
Violation: counter is not persisted; it is recomputed from scratch each time.

**O5 — When `managed_feat_stall_count >= 3`, PM §5n opens a `kind/chore priority/high` issue.**
Title: `"chore: otherness is improving itself but not its managed projects — value delivery has stalled"`
This issue must be deduplicated (not opened again if an identical open issue exists).
Violation: issue is not opened, or opened on every batch (no deduplication).

**O6 — Logic is fail-open.**
If any managed project API call fails, `managed_feat_prs` defaults to 0 for that project (not an exception).
Violation: a single API error crashes the entire §5n step.

---

## Zone 2 — Implementer's judgment

- Where exactly §5n lives in pm.md (after §5m)
- Whether `self_feat_prs` and `managed_feat_prs` are exported as env vars or read from state.json
- Format of the SM §4f health comment line

---

## Zone 3 — Scoped out

- Changing the GREEN/AMBER/RED definition based on `managed_feat_prs` (separate 🔲 item in doc 16)
- Per-project breakdown beyond total managed count
- Historical trend beyond the stall counter
