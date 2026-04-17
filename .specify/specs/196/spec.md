# Spec: chore(design): move deferred D4 item out of COORD queue

> Item: 196 | Risk: low | Size: xs

## Design reference
- **Design doc**: `docs/design/02-human-instruction-interpretation.md`
- **Section**: `§ Future (🔲)`
- **Implements**: removing speculative/deferred item from COORD queue source

---

## Zone 1 — Obligations

**O1**: The "Translation confidence score" item must no longer appear in COORD queue generation output.
**O2**: The item must be preserved in the design doc (not deleted) — just in a section that COORD won't match.

---

## Zone 2 — Implementer's judgment
- Use same pattern as Stage 5 guard: rename ## Future → ## Deferred or ## Speculative.

## Zone 3 — Scoped out
- Does not implement the feature.
