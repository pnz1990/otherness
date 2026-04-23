# Spec: SM §4a simplification cycle issue scheduler

## Design reference
- **Design doc**: `docs/design/45-distil-and-simplify.md`
- **Section**: `§ Future 45.5`
- **Implements**: 45.5 — simplification cycle scheduled (🔲 → ✅)

## Zone 1 — Obligations

**O1**: SM §4a must include a check that fires when `SM_CYCLE % 30 == 0 && SM_CYCLE > 0`.
Violation: the check is absent, or fires at a different interval (e.g., every 10 batches).

**O2**: When the check fires and no open issue with title containing "Simplification cycle" exists,
it must create a `kind/chore,priority/high,size/m,area/agent-loop` issue titled
`chore: Simplification cycle — distil sm.md, coord.md, eng.md, qa.md`.
Violation: issue is not created when SM_CYCLE is a multiple of 30 and no such issue exists.

**O3**: A deduplication guard must prevent opening duplicate issues.
Violation: running the check twice at the same SM_CYCLE opens two issues.

**O4**: If the check cannot fire (SM_CYCLE not set, or = 0), it must skip silently.
Violation: the check errors or opens an issue at SM_CYCLE=0.

**O5**: `scripts/validate.sh` must pass after the change.
Violation: validate.sh exits non-zero.

## Zone 2 — Implementer's judgment

- The check belongs at the end of the §4a bash block (after version pinning check, before ```` ``` ````).
- The interval of 30 is taken from the design doc (§ Simplification cycle: "every 30 batches").
- The issue body should reference `docs/design/45-distil-and-simplify.md`.
- `|| true` on the gh create command — fail silently per AGENTS.md rules for periodic checks.

## Zone 3 — Scoped out

- Changing the SM_CYCLE variable source (it is set upstream in sm.md §4b).
- Adding the simplification cycle logic itself — that is the chore issue's job, not this spec's.
- Altering the check interval from 30 batches.
