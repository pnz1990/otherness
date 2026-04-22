# Spec: issue-884 — /otherness.learn skill-extraction contract

## Design reference
- **Design doc**: `docs/design/31-stage-2-skills-expansion.md`
- **Section**: `§ Future`
- **Implements**: `/otherness.learn` must have a time-bounded skill-extraction contract (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — The learn session MUST produce at least one new or extended skill file, OR document why extraction was not possible in a REJECTION: entry in PROVENANCE.md.**
A learn session that exits with only a PROVENANCE.md update (no skill file change) and no REJECTION: entry violates this obligation.

**O2 — REJECTION: entries in PROVENANCE.md must include a reason code.**
Valid reason codes: `insufficient-patterns`, `skill-already-exists`, `too-project-specific`.
A REJECTION: entry without a valid reason code violates this obligation.

**O3 — If the session exits with only a PROVENANCE.md update and no skill artifact: the learn issue must NOT be closed.**
The learn issue must receive a comment: "⚠️ Learn session produced no skill artifact. Rejection reason: [code]. Issue kept open for next attempt."

**O4 — SM §4c cadence check must confirm a new skill file was written before treating the learn cycle as complete.**
The cadence check must compare skill file count before and after the learn session when evaluating freshness.

---

## Zone 2 — Implementer's judgment

- The REJECTION: entry format should be clear and consistent so SM §4c can parse it reliably.
- The "skill file change" check can compare agent/skills/ file count before vs. after, or check git status for new/modified *.md files in agents/skills/.
- PROVENANCE.md structure: each entry starts with `## YYYY-MM-DD`. REJECTION: entries live within the dated block.
- SM §4c already reads PROVENANCE.md — the cadence check extension should be a simple addition to the existing logic.

---

## Zone 3 — Scoped out

- The `paradigm_category` field in PROVENANCE.md (separate Future item)
- Hard cap on 21-day skills_count check (separate Future item)
- LLM temperature diversity (separate Future item)
- COORD mid-session learn trigger (separate Future item)
