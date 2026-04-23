# Spec: issue-859

## Design reference
- **Design doc**: `docs/design/38-qa-ci-gate.md`
- **Section**: `§ Future`
- **Implements**: 38.5 — `qa.md §3a`: distinguish flaky external checks

---

## Zone 1 — Obligations (falsifiable)

**O1 — Flaky-infrastructure check classification present in qa.md §3a.**
After reading failure details, the code classifies failures as "infrastructure-flaky" if
the failure name or log contains known infrastructure-failure keywords.
- Verify: `grep -q 'infrastructure\|flaky\|runner\|network\|unavailable' ~/.otherness/agents/phases/qa.md`

**O2 — One automatic retry for infrastructure failures before counting as a real failure.**
When a check fails with an infrastructure keyword, the variable `_INFRA_RETRIED` is set
and the iteration continues (re-checks) without incrementing `_CI_ATTEMPTS`.
If the same check fails again (same name, second time): it counts as a real failure.
- Verify: `grep -q '_INFRA_RETRIED\|infra_retry\|INFRA_RETRY' ~/.otherness/agents/phases/qa.md`

**O3 — Retry is bounded: at most one infrastructure retry per check name.**
The retry set tracks check names already retried (`_INFRA_RETRIED_NAMES`). A check that
appears in this set is treated as a real failure on second occurrence.
- Verify: `grep -q '_INFRA_RETRIED_NAMES\|infra_retried_names' ~/.otherness/agents/phases/qa.md`

**O4 — Retry triggers a sleep + re-poll, not a new workflow dispatch.**
Infrastructure flakiness resolves by waiting. The retry mechanism sleeps 30s and
re-polls `gh pr checks` — it does NOT trigger a new CI run.
- Verify: `grep -A5 'infra.*retry\|INFRA_RETRY' ~/.otherness/agents/phases/qa.md | grep -q 'sleep 30'`

**O5 — Infrastructure-retry action is logged clearly.**
The retry posts a message: `[QA §3a] Infrastructure-flaky check '<name>' — retrying once (not counting against attempt limit).`
- Verify: `grep -q 'Infrastructure-flaky check' ~/.otherness/agents/phases/qa.md`

**O6 — Design doc 38.5 flipped from 🔲 to ✅.**
- Verify: `grep -q '✅ 38.5' docs/design/38-qa-ci-gate.md`

---

## Zone 2 — Implementer's judgment

- Infrastructure keywords to check: `timed_out` conclusion (already present in checks), plus log-based heuristics: "network error", "connection refused", "Service Unavailable", "runner lost", "ECONNRESET", "ETIMEDOUT", "timeout exceeded"
- The `timed_out` conclusion from `gh pr checks` is the clearest infrastructure signal — no log analysis needed for that case.
- The retry set `_INFRA_RETRIED_NAMES` is a bash variable — a colon-separated or comma-separated string of check names already retried this iteration.
- Place the infrastructure-flaky check block BEFORE the DCO check and BEFORE the general CI fix loop — so it fires immediately on the first infrastructure signal.

---

## Zone 3 — Scoped out

- Retrying non-infrastructure failures (spec violations, code errors) — these are always real failures
- More than one retry — the design doc says "one automatic retry"
- Modifying anything outside qa.md and the design doc
