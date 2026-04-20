# Spec: PM §5f Documentation Health Scan + Merge Conflict Fix

## Design reference
- **Design doc**: `docs/design/04-documentation-health.md`
- **Section**: `§ Present — PM §5f periodic doc health scan`
- **Implements**: Fix corrupted §5f merge conflict markers + add executable implementation; add lint check for conflict markers (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1** — `agents/phases/pm.md` must NOT contain any git merge conflict markers (`<<<<<<< HEAD`, `=======`, `>>>>>>>`). Violation: grep finds these patterns.

**O2** — `agents/phases/pm.md` §5f must contain executable python3 code (not `[AI-STEP]` comments) that: (a) reads merged PR titles, (b) scans `docs/design/*.md` for Present items without `(PR #N)` references, (c) scans for Future items matching merged PR titles, (d) checks freshness (>60d). Violation: §5f contains only comments with no executable `python3 - <<'...'` block.

**O3** — `scripts/lint.sh` must detect and fail on git merge conflict markers in any file under `agents/`. Violation: running lint.sh on a file with `<<<<<<< HEAD` returns exit 0.

**O4** — `docs/design/04-documentation-health.md` Present items for §5f must include a PR reference for this fix. Violation: PR reference absent.

**O5** — All validate and lint checks pass in the worktree. Violation: non-zero exit.

---

## Zone 2 — Implementer's judgment

- The python3 block in §5f uses subprocess to call `gh`, consistent with all other phase python3 blocks.
- Duplicate suppression uses the open_if_absent pattern (search for open issue with matching title prefix before creating).
- Freshness threshold: 60 days (per design doc Zone 2).

---

## Zone 3 — Scoped out

- Cross-checking README/AGENTS.md claims (separate item 254)
- Per-PR CI lint for conflict markers (only lint.sh coverage in scope)
