# Spec: issue-895 — ENG phase gate: verification step for ✅ Present marking (design doc 41.4)

## Design reference
- **Design doc**: `docs/design/41-design-doc-integrity.md`
- **Section**: `§ Future`
- **Implements**: 41.4 — ENG §2c must add verification step when marking design doc item ✅ Present (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — ENG §2c (implementation checklist) must add explicit verification steps for three item types.**
Before ENG marks any design doc item ✅ Present, the spec.md must include one of:
- "If new `state.json` field: verify field appears in `_state` branch after implementation"
- "If new metrics column: verify last metrics row contains the column"
- "If new agent instruction section: verify section header appears in target agent file"

**O2 — QA §3b adversarial review must check that ENG included a verification step.**
A PR that marks ✅ Present without a verification step in spec.md is a WRONG finding that blocks merge.

**O3 — The verification check is added as an instruction to ENG §2f (update design doc).**
The instruction must explicitly say: before flipping 🔲 to ✅, verify the feature is actually present.

---

## Zone 2 — Implementer's judgment

- The verification is a documentation obligation, not a runtime check. The agent reads the instruction and performs the appropriate check before flipping the emoji.
- The three verification patterns cover the most common "marked Present but didn't run" failure modes.
- QA's check is: "does spec.md have a verification note?" — not "did the agent actually verify." The agent is trusted to follow the instruction; QA verifies the instruction was documented.

---

## Zone 3 — Scoped out

- 41.1-41.3 (downstream detection, separate items)
- 41.5 (periodic audit, separate item)
- Runtime/automated verification of all ✅ Present items
