# Spec: Design doc freshness metric

> Item: 253 | Created: 2026-04-18 | Status: Active

## Design reference
- **Design doc**: `docs/design/04-documentation-health.md`
- **Section**: `## Future`
- **Implements**: Design doc freshness metric (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — PM phase §5f includes a freshness check sub-step.**
The `## 5f. Documentation health scan` section in `agents/phases/pm.md` must include
a freshness check as Step 5 (or appended to the existing [AI-STEP]):

For each `docs/design/*.md` file: check when it was last modified in git (`git log -1
--format=%ar -- docs/design/<fname>`) vs the most recent merged PR. If the file has
not been touched in more than N days (default 60), open a `kind/docs` issue:
`"docs: design doc <fname> may be stale — no updates in <N> days"`.

Behavior that violates this: the freshness check is absent from §5f.

**O2 — The freshness check is gated behind the same N_PM_CYCLES cadence.**
It runs inside the existing `if [ $((${PM_CYCLE:-0} % ${N_PM_CYCLES:-3})) -eq 0 ]`
block. It does not run on every cycle.

Behavior that violates this: freshness check runs every single PM cycle.

**O3 — Duplicate-suppressed: only one open issue per design doc.**
Before opening a freshness issue, check for an existing open issue with the same
title (same `open_if_absent` pattern as the rest of §5f).

Behavior that violates this: a new issue is opened every time the scan runs for a
stale doc.

**O4 — Graceful fallback when git log returns no date.**
If `git log -1 --format=%ar -- <file>` returns empty (file has no git history yet),
skip the file without error.

Behavior that violates this: the scan crashes when a design doc has no git history.

---

## Zone 2 — Implementer's judgment

- How many days for "stale": 60 days default. Hard-code in the [AI-STEP] comment as
  the default. Future: configurable via otherness-config.yaml stale_days.
- How to get git age in a shell-scripting context: `git log -1 --format=%ct --
  docs/design/<fname>` returns Unix timestamp. Compare to `date +%s`. Division by 86400.
- Whether to add §5g or extend §5f: extend §5f as a new step 5 in the existing
  [AI-STEP] comment block — no new section header needed.
- Whether to check customer docs (docs/*.md) for freshness: not in scope for this item.
  Design docs only.

---

## Zone 3 — Scoped out

- Per-file configurable stale thresholds
- Customer doc freshness (docs/*.md)
- Code freshness (comparing design doc age to code commit dates)
- Automatic doc edits to mark stale docs — issues only, never self-edit
