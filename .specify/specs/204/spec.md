# Spec: wire difficulty-ledger.md into eng.md (#204)

## Design reference
- N/A — agent instruction update with no user-visible behavior change

## Zone 1 — Obligations

**O1** — `eng.md §2b` contains a `Load skill: difficulty-ledger.md` instruction before the spec-writing step.

Falsifiable: `grep "difficulty-ledger" agents/phases/eng.md` returns at least one match.

**O2** — The load instruction appears before the spec quality gate (Zone 1 obligations check), not after.

Falsifiable: the load instruction appears before the line "Spec quality gate".

## Zone 2 — Implementer's judgment
- Exact placement: after loading declaring-designs.md, before writing the spec.
- Instruction text: one line, same pattern as other skill loads.

## Zone 3 — Scoped out
- Changing when or how the difficulty ledger is written (that is SM phase work)
