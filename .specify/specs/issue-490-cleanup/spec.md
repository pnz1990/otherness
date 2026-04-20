# Spec: Mark rollout items as Present in design docs 28 and 29

## Design reference
- **Design doc**: `docs/design/28-dual-step-scheduled-workflow.md`, `docs/design/29-continuous-code-hygiene.md`
- **Section**: `## Future`
- **Implements**: N/A — infrastructure verification (rollout already done, updating docs to reflect reality)

---

## Zone 1 — Obligations

**O1 — Design doc 28 Future item (Roll out dual-step workflow) moved to Present.**
All 3 managed projects (alibi, kardinal-promoter, kro-ui) confirmed to have the
dual-step workflow deployed. The 🔲 item must be promoted to ✅.

**O2 — Design doc 29 Future item (Roll out hygiene config) moved to Present.**
All 3 managed projects confirmed to have `hygiene:` section in otherness-config.yaml.
The 🔲 item must be promoted to ✅.

---

## Zone 2 — Implementer's judgment

- No code changes required, only design doc updates.

---

## Zone 3 — Scoped out

- Verifying the hygiene config is correctly configured in each project (quality check)
- Checking if hygiene scans are actually running on each project
