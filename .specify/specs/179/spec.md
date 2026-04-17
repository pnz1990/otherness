# Spec: feat(sm): skill confidence scoring

> Item: 179 | Risk: medium | Size: m | Tier: CRITICAL (sm.md — phases file)

## Design reference
- N/A — new SM subsection for skill quality maintenance (docs/future-ideas.md Idea 6)

---

## Zone 1 — Obligations

**O1**: sm.md must include a new subsection (between §4c and §4d) that checks each skill file for:
- Not loaded recently (no reference in phases/*.md or standalone.md within last 6 months)
- Content appears contradicted by a newer skill file
- Older than 90 days with no updates
- **Falsified by**: No skill confidence check in SM phase after PR.

**O2**: The check is AI-STEP only — it produces a comment/warning, never modifies skill files autonomously.
- **Falsified by**: SM phase deletes or modifies a skill file.

**O3**: Results are posted as a comment on REPORT_ISSUE (not as a [NEEDS HUMAN] escalation — just informational).
- **Falsified by**: A [NEEDS HUMAN] is posted when skill confidence is low.

**O4**: Change is a new section insertion between §4c and §4d — no existing sections modified.
- **Falsified by**: Any existing sm.md section content changed.

---

## Zone 2 — Implementer's judgment

- Frequency: once per 10 SM cycles (same as PM competitive check)
- What "not loaded recently" means: skill filename doesn't appear in any grep of phases/*.md or standalone.md
- Whether to check for contradictions: basic overlap detection (same topic name in 2 skill files)

---

## Zone 3 — Scoped out

- Does NOT auto-deprecate skills
- Does NOT merge skill files
- Does NOT change any skill content
