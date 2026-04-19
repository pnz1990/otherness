# Spec: PM §5 reference project health check

> Item: 301 | Created: 2026-04-19 | Status: Active

## Design reference
- **Design doc**: `docs/design/16-journey-2-reference-project.md`
- **Section**: `§ Future`
- **Implements**: PM §5 reference project health check — detect Journey 2 failure, [NEEDS HUMAN] once per stall (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — PM phase has a reference project health check that detects Journey 2 failure.**
A [AI-STEP] block in PM §5 (or §5j as a new sub-section) checks whether the reference
project's `_state` branch has been updated within 72 hours.

**O2 — When Journey 2 fails, the agent opens a [NEEDS HUMAN] issue exactly once per stall event.**
Issue title: `"[NEEDS HUMAN] Journey 2: reference project stalled >72h — restart otherness on <project>"`.
Check for an existing open issue with this title before creating (duplicate suppression).

**O3 — The check runs every N_PM_CYCLES cycles.**

**O4 — Design doc 16 marks this item as ✅ Present.**

---

## Zone 2 — Implementer's judgment

- Placement: new §5j in pm.md, after §5i.
- Reference project: first non-otherness entry in otherness-config.yaml monitor.projects.
- Threshold: 72 hours (matches test.sh check 5b).

---

## Zone 3 — Scoped out

- AMBER/RED escalation based on duration (that's item 302)
- Per-project health checks beyond the reference project
