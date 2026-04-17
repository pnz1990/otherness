# Spec: feat(sm): cross-project pattern mining — needs-human issues

> Item: 171 | Risk: medium | Size: m | Tier: CRITICAL (sm.md — phases file)

## Design reference
- N/A — enhancement to existing stub in sm.md §4c (docs/future-ideas.md Idea 8)

---

## Zone 1 — Obligations

**O1**: sm.md §4c must be expanded with a detailed [AI-STEP] that actually performs cross-project pattern mining, replacing the minimal stub.
- **Falsified by**: §4c still says only "Find patterns appearing in ≥2 projects" without actionable detail.

**O2**: The AI-STEP must read `monitor.projects` from `otherness-config.yaml` to get the project list.
- **Falsified by**: AI-STEP hardcodes any project name.

**O3**: Pattern extraction must produce entries that reference no specific project names.
- **Falsified by**: Any extracted pattern entry contains a project name or repo slug.

**O4**: The change is confined to §4c AI-STEP expansion — no new sections added to sm.md.
- **Falsified by**: New section added or existing sections modified.

---

## Zone 2 — Implementer's judgment

- How to structure the AI-STEP: numbered steps (1-5) matching docs/future-ideas.md Idea 8
- Whether to fire when only 1 project: yes, but output note "need ≥2 projects for cross-project patterns"

---

## Zone 3 — Scoped out

- Does NOT implement automatic skill file PR creation
- Does NOT change the frequency trigger (still every 5 SM cycles)
