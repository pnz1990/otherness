# Spec: feat(pm): cross-project improvement proposals

> Item: 175 | Risk: medium | Size: m | Tier: CRITICAL (pm.md — phases file)

## Design reference
- N/A — enhancement to pm.md §5c stub (docs/future-ideas.md Idea 5)

---

## Zone 1 — Obligations

**O1**: pm.md §5c must be expanded with a [AI-STEP] that looks across all monitored projects for common blockers, not just competitive analysis.
- **Falsified by**: §5c still only mentions competitive analysis without cross-project blocker detection.

**O2**: When ≥2 projects share the same blocker (needs_human open, CI red, 0 velocity), PM must open an issue on the otherness repo proposing an improvement.
- **Falsified by**: PM runs the check but opens no issue even when ≥2 projects share a blocker.

**O3**: The issue proposal must not contain project-specific information (project names must be abstracted).
- **Falsified by**: Issue body contains a specific project repo slug.

**O4**: Change confined to §5c stub replacement — no new sections in pm.md.
- **Falsified by**: New section added or existing sections outside §5c modified.

---

## Zone 2 — Implementer's judgment

- Frequency: keeps current "every 10 PM cycles" trigger
- What "common blocker" means: same category of needs-human issue, both CI red, or both 0 velocity
- Issue title format: "improvement(loop): <abstract pattern> affecting ≥2 managed projects"

---

## Zone 3 — Scoped out

- Does NOT implement competitive analysis against external tools (that's separate)
- Does NOT aggregate metric data across projects (only needs-human + CI status)
