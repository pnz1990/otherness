# Spec: CI Provider Abstraction (#114)

## Zone 1 — Obligations (falsifiable)

### O1: CI_PROVIDER dispatched in coord.md
The CI check in `coord.md` §1a reads `CI_PROVIDER` from `otherness-config.yaml` and dispatches:
- `github-actions` → existing `gh run list` path
- `circleci` → CircleCI v2 API call (warns if token not set, skips gate rather than silently passing)
- `gitlab` → GitLab pipelines API call (warns if token not set, skips gate)
- Unknown → warn and skip CI gate explicitly (log the skip, don't silently pass)
- **Violation**: A non-GitHub project proceeds to claim work without any CI check or warning.

### O2: Acceptance test passes
```bash
grep -c "CI_PROVIDER\|circleci\|gitlab" ~/.otherness/agents/phases/coord.md  # ≥ 1
```
Note: acceptance test in issue says `standalone.md` but the CI check lives in `coord.md`. Satisfying `coord.md` is correct; `standalone.md` reads `CI_PROVIDER` in startup so both can satisfy.

### O3: Unknown provider is logged, not silently skipped
When CI_PROVIDER is unknown, the agent prints a warning that includes the provider name.
- **Violation**: Agent proceeds without any output when provider is unrecognized.

---

## Zone 2 — Implementer's judgment

- Whether to also update `standalone.md` startup to export `CI_PROVIDER` (recommended — cleaner dispatch).
- Exact CircleCI API endpoint and token env var name (`CIRCLE_TOKEN`).
- Exact GitLab API endpoint and token env var name (`GITLAB_TOKEN`).
- Whether to support `bitbucket` (low-demand — skip for now, log as unknown).

---

## Zone 3 — Scoped out

- Full CircleCI/GitLab CI failure detail reporting (just green/red is enough).
- Automatic token provision.
- Other CI providers (Jenkins, Travis, etc.) — unknown → skip is sufficient.
