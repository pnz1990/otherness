# Spec: issue-900 — Add observability.otlp section to otherness-config-template.yaml

## Design reference
- **Design doc**: `docs/design/44-otlp-observability.md`
- **Section**: `§ Future — Layer 1: Session telemetry (OTLP)`
- **Implements**: 44.1 — `otherness-config-template.yaml`: add `observability.otlp` section (backend, enabled, service_name, endpoint_secret, headers_secret) (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1** — `otherness-config-template.yaml` must contain an `observability:` top-level key with a nested `otlp:` block.

**O2** — The `otlp:` block must contain exactly these fields (with defaults): `enabled: false`, `backend: aws-xray`, `service_name: otherness`, `endpoint_secret: OTEL_EXPORTER_OTLP_ENDPOINT`, `headers_secret: OTEL_EXPORTER_OTLP_HEADERS`.

**O3** — The `enabled` field must default to `false` (O1 from design doc: Zero config = zero telemetry).

**O4** — The block must include inline comments explaining each field and the supported backend values (`aws-xray | grafana | prometheus | custom`), consistent with the Layer 1 config example in `docs/design/44-otlp-observability.md`.

**O5** — `scripts/validate.sh` must pass after the change (no structural regressions).

**O6** — `scripts/lint.sh` must pass after the change.

**O7** — The design doc `docs/design/44-otlp-observability.md` must be updated to move 44.1 from 🔲 Future to ✅ Present.

---

## Zone 2 — Implementer's judgment

- Placement: add the `observability:` section after the `anchor:` block (end of file), as a new top-level section. This maintains the logical progression: project → maqa → ci → projects → monitoring → scheduled → simulation → hygiene → anchor → observability.
- The section should be commented out by default (like `schedule:`, `simulation:`, `hygiene:`), since it is opt-in and most users will not enable it immediately.
- A brief header comment explaining the four-layer model and pointing to the design doc is appropriate.

---

## Zone 3 — Scoped out

- Implementing the workflow step to inject OTLP env vars (44.2, 44.3) — separate items.
- AWS X-Ray ADOT sidecar (44.4) — separate item.
- User-facing observability guide (44.5) — separate item.
- Any changes to agent phases or standalone.md.
- Changes to `otherness-config.yaml` (the live project config, not the template).
