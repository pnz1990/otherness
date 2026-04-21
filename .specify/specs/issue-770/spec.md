# Spec: /otherness.upgrade upgrade_policy display

## Design reference
- **Design doc**: `docs/design/03-versioned-release.md`
- **Section**: `§ Future`
- **Implements**: `/otherness.upgrade` interactive command updated to respect upgrade_policy — shows what the policy allows before prompting (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — The command reads and displays upgrade_policy from otherness-config.yaml.**
When the operator runs `/otherness.upgrade`, the output must include the current
`upgrade_policy` value (e.g. `"0.x.x"`, `"0.2.x"`, or "unset — fully pinned").
Violation: command runs without mentioning upgrade_policy.

**O2 — The command shows what the policy allows.**
Given the current `agent_version` and `upgrade_policy`, the command must display
which available releases satisfy the policy (versions that would be auto-upgraded to).
Violation: available releases listed without filtering by policy.

**O3 — The command flags if the current version is outside the policy.**
If `agent_version` is set but not a valid tag matching `upgrade_policy`, the command
must print a warning. Violation: silent when version/policy mismatch exists.

**O4 — Graceful fallback when upgrade_policy is absent.**
If `upgrade_policy` is not set in otherness-config.yaml, the command must display
"upgrade_policy: unset — pinned to current version, no auto-upgrade".
Violation: command errors or prints nothing when upgrade_policy missing.

---

## Zone 2 — Implementer's judgment

- Where to add the policy display: in Step 1 (current pin), alongside `agent_version`
- Policy matching logic: use semver prefix matching — "0.x.x" allows any 0.*.*, "0.2.x" allows 0.2.*
- Whether to reorder steps: no — keep existing flow, add policy info to Step 1
- Whether to add a "upgrade now" action: no — this is display only; the existing Step 4 handles pinning

---

## Zone 3 — Scoped out

- Automatically upgrading based on upgrade_policy (that is the workflow's job, not this command)
- Validating the policy against known semver rules
- Showing diff of changes between versions
