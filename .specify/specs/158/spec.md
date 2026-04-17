# Spec: docs(design): add guard to Stage 5 Future items

> Item: 158 | Risk: low | Size: xs

## Design reference
- **Design doc**: `docs/design/03-versioned-release.md`
- **Section**: `§ Future (🔲)`
- **Implements**: Guard preventing premature Stage 5 queue item generation

---

## Zone 1 — Obligations

**O1**: The Stage 5 design doc's Future items must not appear in the COORD queue until Stage 5 is triggered. The fix must be structural (not rely on agent reading prose instructions).
- **Falsified by**: COORD queue generator includes Stage 5 items in the queue when Stage 5 has not been triggered.

**O2**: The `## Future` section header in `03-versioned-release.md` must be renamed to something that does NOT match the COORD regex `r'^## Future'`.
- **Falsified by**: COORD still reads 5 items from doc 03 after this PR.

**O3**: The renamed section must clearly communicate to a human reader that these items are deferred pending a trigger.
- **Falsified by**: Section name doesn't mention "trigger" or "pending" or similar.

---

## Zone 2 — Implementer's judgment

- New section name: `## Future (🔲) — Stage 5 trigger required` or `## Planned (🔲 — pending Stage 5 trigger)`
- The COORD regex is `r'^## Future'` — any other prefix avoids the match.

---

## Zone 3 — Scoped out

- Does NOT update the COORD queue generator logic (no phase file changes)
- Does NOT implement any Stage 5 deliverables
