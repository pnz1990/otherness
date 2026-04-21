# Spec: PM §5j — Managed Project Feature Velocity Gate

**Item**: issue-713
**Design doc**: `docs/design/16-journey-2-reference-project.md`
**Section**: `§ Future` (🔲 → ✅)

## Design reference

- **Design doc**: `docs/design/16-journey-2-reference-project.md`
- **Section**: `§ Future`
- **Implements**: "PM §5j: managed project feature velocity gate" (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1**: After the _state freshness check passes (AGE_H ≤ 72h), PM §5j performs a second check: count PRs merged in the last 7 days on the reference project that match `kind/enhancement` label OR whose branch/title begins with `feat/`.

**O2**: If that count is zero and the reference project exists and is reachable, JOURNEY2_HEALTH is set to AMBER (it must not be OK or GREEN when no meaningful PRs shipped).

**O3**: The check is fail-open: if the GitHub API call fails (rate-limit, auth error, repo not accessible), the velocity gate is skipped and the existing stale/alive judgment is used unchanged. A network error must NOT set JOURNEY2_HEALTH to AMBER.

**O4**: The AMBER downgrade due to zero feature velocity opens an issue `[VELOCITY] Reference project has no feat PRs in 7 days: <ref_project>` exactly once (deduplicated by title search). It does NOT open a `[NEEDS HUMAN]` issue — this is a soft signal, not a hard block.

**O5**: The implementation is entirely within `agents/phases/pm.md` §5j bash block. No other file is modified except `docs/design/16-journey-2-reference-project.md` (design doc update: 🔲 → ✅).

**O6** (falsifiable): when JOURNEY2_HEALTH is downgraded from OK to AMBER by the velocity gate, the log line `[PM §5j] Journey 2 AMBER: reference project has no feat PRs in last 7 days` appears. When the velocity gate passes (≥1 feat PR), the log line `[PM §5j] Journey 2 velocity OK: N feat PRs in last 7d` appears.

---

## Zone 2 — Implementer's judgment

- Where exactly in the §5j bash block to insert the velocity check (after AGE_H ≤ 72h branch or as a separate final block).
- How to query merged PRs: `gh pr list --repo $REF_PROJECT --state merged --limit 30 --json title,labels,headRefName,mergedAt` — parse in python3.
- Whether to use `--search` flag or post-filter in python3.
- The exact 7-day window calculation.

---

## Zone 3 — Scoped out

- Changes to standalone.md (CRITICAL tier — not in scope).
- Changing the RED threshold (only AMBER for zero-velocity; RED remains stale-hours-based).
- Velocity gates on projects other than the reference project.
- Tracking velocity over multiple batches (single-window: last 7 days).
