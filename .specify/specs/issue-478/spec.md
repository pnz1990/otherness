# Spec: feat(security): M2 — agent_version pin in otherness-config.yaml

## Design reference
- **Design doc**: `docs/design/27-security-model.md`
- **Section**: `§ Mitigations — M2 — Pin otherness git clone to a SHA (P0)`
- **Implements**: M2: Set `agent_version` in all `otherness-config.yaml` files to pin otherness clone (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — `otherness-config.yaml` has `agent_version` set under `maqa:`.**
Violation: `agent_version` field is absent or empty in `otherness-config.yaml`.

**O2 — `otherness-config-template.yaml` has `agent_version:` with a comment explaining its security purpose.**
Violation: The template does not document `agent_version` or its security rationale.

**O3 — `validate.sh` passes without error.**
Violation: `bash scripts/validate.sh` exits non-zero after this change.

**O4 — `test.sh` passes without error.**
Violation: `bash scripts/test.sh` exits non-zero after this change.

**O5 — `lint.sh` passes without error.**
Violation: `bash scripts/lint.sh` exits non-zero after this change.

**O6 — The `agent_version` value is a real, existing tag or commit SHA in the otherness repo.**
Violation: The value is a placeholder string that doesn't resolve to an actual ref.

---

## Zone 2 — Implementer's judgment

- Whether to use a tag name (e.g. `v0.1.0`) or a raw SHA. 
  Preference: tag name for readability if a tag exists; SHA if no tag yet.
- Whether to also update `otherness-config-template.yaml` active section or comments-only.
  Preference: document in comments so adopters understand to set this value.
- The design doc mentions "set in all 3 otherness-config.yaml files" — the other two
  are in managed project repos (not this repo). This PR covers the otherness repo only.
  Cross-project changes are out of scope for this item.

---

## Zone 3 — Scoped out

- Creating a formal release tag/process (that is a separate item)
- Updating managed project repos' `otherness-config.yaml` (cross-project, separate item)
- Adding CI enforcement that `agent_version` is set (future hardening)
- Adding SHA verification logic to the `standalone.md` SELF-UPDATE block (already handled
  when `agent_version` is set — the block does `git checkout $AGENT_VERSION`)
