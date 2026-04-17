# Spec: fix(dod): Journey 2 FAILING — alibi _state stalled >72h

> Item: 146 | Risk: low | Size: xs

## Design reference
- N/A — infrastructure change with no user-visible behavior change (docs-only fix)

---

## Zone 1 — Obligations

**O1**: `docs/aide/definition-of-done.md` Journey Status table must accurately reflect the current state of each journey. Journey 2 is currently ❌ Failing (alibi `_state` last commit > 72h ago, no queue activity). The table must be updated to show this.
- **Falsified by**: Journey Status shows "✅ Passing" when alibi `_state` is >72h stale.

**O2**: A `[NEEDS HUMAN]` comment must be posted on the alibi report issue (pnz1990/alibi#1) explaining that otherness has not run in >3 days and requesting a session restart.
- **Falsified by**: No such comment exists on alibi#1 after this item ships.

**O3**: The DoD Journey Status table must include the date the check was last performed (ISO date, not "N days ago" or relative).
- **Falsified by**: The table lacks a current date in the "Last checked" column.

---

## Zone 2 — Implementer's judgment

- Wording of the [NEEDS HUMAN] comment is up to the engineer. Must be actionable.
- Journey 1, 3, 4, 5 statuses should be re-verified and updated if stale.

---

## Zone 3 — Scoped out

- Does NOT fix why alibi is stalled — that requires a human to restart a session.
- Does NOT change any agent instruction files.
- Does NOT modify scripts or CI.
