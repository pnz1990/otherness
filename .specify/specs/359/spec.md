# Spec: security(p1): protect _state branches on all 3 repos

## Design reference
- **Design doc**: `docs/design/27-security-model.md §M7`
- **Section**: `§ Mitigations — M7`
- **Implements**: M7: `_state` branch protection applied on all repos (🔲 → ✅)

---

## Zone 1 — Obligations

**O1** — `_state` branch on `pnz1990/otherness` must have branch protection that
prevents force-pushes (`allow_force_pushes: false`) and branch deletion (`allow_deletions: false`).

Violation: force-push to _state succeeds for any authenticated user.

**O2** — Same protection applied to all repos in `monitor.projects` that have a `_state` branch.

Violation: protection only on otherness, not on managed projects.

**O3** — Agent direct-push to `_state` continues to work (no PR requirement, no required reviews).

Violation: agent cannot push state.json updates (breaks the distributed lock).

---

## Zone 2 — Implementer's judgment

- PR requirement for _state was not added — agent writes state.json directly without creating PRs.
  Adding require_pull_request_reviews would break the agent. Deferred until M3 (GitHub App).
- The protection via API call is a one-time setup action, not repeated on every SM cycle.

---

## Zone 3 — Scoped out

- Restricting push to specific users/apps (M3 — GitHub App — is the proper fix)
- CODEOWNERS for _state (GitHub does not apply CODEOWNERS to non-main branches by default)
- Cross-project enforcement via SM every batch (the protection is idempotent; checking/re-applying is O(3 API calls) and can be added to SM later)
