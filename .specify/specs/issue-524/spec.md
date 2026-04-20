# Spec: otherness-config.yaml `anchor:` section

**Item**: issue-524
**Branch**: feat/issue-524

## Design reference

- **Design doc**: `docs/design/25-anchor-kardinal-promoter.md`
- **Section**: `§ Future`
- **Implements**: `otherness-config.yaml: anchor: section — workflow, score_pattern, coverage_target: 80, stagnation_sessions: 3` (🔲 → ✅)

---

## Zone 1 — Obligations

**O1** — `otherness-config.yaml` must contain an active (uncommented) `anchor:` section with fields: `workflow`, `score_pattern`, `coverage_target: 80`, `stagnation_sessions: 3`.

Violation: `anchor:` section is absent or remains commented out.

**O2** — `otherness-config-template.yaml` must contain the `anchor:` section as a first-class section with inline documentation comments explaining each field.

Violation: `anchor:` section is absent from the template or remains fully commented out.

**O3** — The `anchor.workflow` value in `otherness-config.yaml` must be empty string (`""`) since the otherness repo itself does not have a PDCA/anchor workflow.

Violation: `workflow` field has a non-empty value pointing to a non-existent workflow.

---

## Zone 2 — Implementer's judgment

- Whether to add `anchor:` before or after `simulation:`: add after `hygiene:`, before `simulation:`. Logical grouping — anchor is a quality signal, hygiene is also quality.
- `score_pattern` default: `"PASS=([0-9]+) FAIL=([0-9]+)"` — matches the kardinal-promoter PDCA pattern and is generic enough for other projects.
- Template comment style: match existing template comment style (## header + line comments per field).

---

## Zone 3 — Scoped out

- Configuring `anchor:` for managed projects (kardinal-promoter, kro-ui) — those are separate items
- Adding `anchor:` to `otherness.setup` or `otherness.onboard` workflows (separate item)
- Validating that `anchor.workflow` exists in the repo (scripts/validate.sh concern)
