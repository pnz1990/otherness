# Spec: feat(config): add anchor: section to otherness-config.yaml and template

## Design reference
- **Design doc**: `docs/design/24-project-anchor-framework.md`
- **Section**: `§ otherness-config.yaml anchor fields`
- **Implements**: `otherness-config.yaml` + template: add `anchor:` section (workflow, score_pattern, coverage_target, stagnation_sessions) (🔲 → ✅)

---

## Zone 1 — Obligations

**O1** — `otherness-config.yaml` gains an `anchor:` section with these fields (commented-out
by default, since otherness itself has no anchor workflow):
- `workflow`: filename of the workflow that runs the anchor
- `score_pattern`: regex to extract pass/fail counts from issue comment
- `coverage_target`: integer, minimum % coverage
- `stagnation_sessions`: integer, sessions without growth before anchor prioritization

Violation: any of the 4 fields missing from the section.

**O2** — `otherness-config-template.yaml` gains the same `anchor:` section (also commented-out,
since new projects start without an anchor), with documentation comments explaining each field.

Violation: template not updated.

**O3** — The existing fields in both files are not modified. Only additive changes.

Violation: any existing field removed or changed.

---

## Zone 2 — Implementer's judgment

- Whether to include `report_issue` field: the design doc shows it but it defaults to the
  project's main REPORT_ISSUE. Omit from the config to avoid duplication.
- Comment style: use `#` comments, consistent with existing config style.
- Placement: add after `monitor:` section in both files.

---

## Zone 3 — Scoped out

- SM §4g-anchor (gap detection) — separate issue 355
- COORD §1c anchor-growth gate — separate issue 356
- Implementing the anchor workflow itself — out of scope for this project
