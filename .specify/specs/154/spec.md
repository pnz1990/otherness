# Spec: feat(eng): persist D4 translation artifact

> Item: 154 | Risk: medium | Size: s | Tier: CRITICAL (standalone.md)

## Design reference
- **Design doc**: `docs/design/02-human-instruction-interpretation.md`
- **Section**: `§ Future (🔲)`
- **Implements**: Translation artifact persisted in spec (🔲 → ✅)

---

## Zone 1 — Obligations

**O1**: After an IMPERATIVE instruction is translated, the `[📋 D4 TRANSLATION]` block must be saved to `.specify/d4/translation.md` before the agent proceeds with implementation. (Note: D4 fires at session start before ITEM_ID is set — use `.specify/d4/` not `.specify/specs/$ITEM_ID/`.)
- **Falsified by**: Agent proceeds with implementation without writing translation.md.

**O2**: The translation artifact must be written before the agent acts on the translation — not after.
- **Falsified by**: translation.md is written after the first implementation commit.

**O3**: The change must not break any existing behavior. Infra-only instructions (no translation) must continue to skip translation.md creation.
- **Falsified by**: INFRA-classified instructions trigger translation.md creation.

**O4**: The instruction is a 1-3 line addition to standalone.md §D4 — no restructuring of existing logic.
- **Falsified by**: More than 5 lines of standalone.md changed, or any existing prose removed.

**O5**: `docs/design/02-D4.md` `## Future` must be updated: `🔲 Translation artifact persisted` → `✅ Present`.
- **Falsified by**: Item still in Future section after merge.

---

## Zone 2 — Implementer's judgment

- File path: `.specify/specs/$ITEM_ID/translation.md` (same directory as spec.md)
- Whether to create the directory if it doesn't exist: yes, use `mkdir -p`
- Format: write the full `[📋 D4 TRANSLATION]` block verbatim

---

## Zone 3 — Scoped out

- Does NOT validate translation quality (just saves the artifact)
- Does NOT block on translation.md missing from existing items
- Does NOT change eng.md or qa.md
