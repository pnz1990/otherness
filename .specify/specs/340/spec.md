# Spec: feat(config): add maqa.session_item_limit field

## Design reference
- **Design doc**: `docs/design/21-session-throughput.md`
- **Section**: `§ Future`
- **Implements**: `otherness-config.yaml` + `otherness-config-template.yaml`: add `maqa.session_item_limit` field (default: 10) (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — `session_item_limit` field must exist in `otherness-config.yaml` under `maqa:` with value 10.**
The field is present in the live config with a `# max items per session before SM/PM gate` comment.
Violation: field absent, or under a different section, or default value differs from 10.

**O2 — `session_item_limit` field must exist in `otherness-config-template.yaml` under `maqa:` with a setup comment.**
The template is what new projects copy — it must include this field so new projects get it.
Violation: field present in `otherness-config.yaml` but absent from template.

**O3 — Design doc 21 must be updated: `session_item_limit` config items moved from 🔲 to ✅ in Present.**
Violation: design doc Future section still has the config field item after this PR.

---

## Zone 2 — Implementer's judgment

- Whether to add an inline comment explaining the field: yes — it is not self-explanatory.
- Exact default value: 10 as specified by design doc O1.
- Whether to validate the field value in scripts: out of scope for this item (config read-side only).

---

## Zone 3 — Scoped out

- Reading `session_item_limit` in the agent loop (that is the coord.md change, a separate CRITICAL-tier item)
- Validating the value is a positive integer
- Per-project default overrides
