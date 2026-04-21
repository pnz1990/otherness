# Spec: Architectural monoculture breakout mechanism

**Issue**: #649

## Design reference

- **Design doc**: `docs/design/31-stage-2-skills-expansion.md`
- **Section**: `§ Future`
- **Implements**: Architectural monoculture breakout mechanism (🔲 → ✅)

---

## Intent

All agents share `standalone.md` — the same reasoning framework. Skill diversity ≠
conceptual diversity. The only current break is `/otherness.learn` importing foreign
patterns. This must be made systematic: every learn session must explicitly target a
repo from a different paradigm than the last session. SM §4c records `paradigm_category`
from PROVENANCE.md and refuses back-to-back sessions in the same category.

---

## Zone 1 — Obligations

**O1** — `agents/otherness.learn.md` §Step 5 PROVENANCE.md format requires a
`paradigm_category:` field in each entry. Valid values:
`functional`, `event-sourced`, `actor-model`, `imperative-oop`, `declarative-config`,
`reactive`, `domain-driven`, `protocol-oriented`, `other`.

**O2** — SM §4c (learn cadence enforcement) must parse the last `paradigm_category:`
from PROVENANCE.md entries. When opening a new learn issue, include the last paradigm
category in the issue body as guidance: "Last learn paradigm: X. Target a different
paradigm this session."

**O3** — If the last 2 PROVENANCE.md entries have the same `paradigm_category`, the
SM §4c learn issue body must include a warning: "⚠️ Same paradigm as last session —
diversity gate: select a repo from a different category."

**O4** — Fail-open: if PROVENANCE.md has no `paradigm_category` fields (existing entries
pre-date this feature), treat as no constraint. No blocking on missing data.

**O5** — Design doc `docs/design/31-stage-2-skills-expansion.md` has item flipped 🔲 → ✅.

---

## Tasks

- [AI] Update PROVENANCE.md format in otherness.learn.md §Step 5 to include `paradigm_category:`
- [AI] Add `paradigm_category` guidance to the learn issue body in SM §4c
- [AI] Add same-paradigm warning when last 2 entries share a category
- [CMD] Flip design doc item 🔲 → ✅
- [CMD] Run validate.sh + lint.sh

---

## Non-scope

- Not enforcing a hard block on same-paradigm (advisory only — fail-open)
- Not retroactively updating existing PROVENANCE.md entries
- Not adding paradigm enforcement to otherness.learn itself (checking is SM's job)
