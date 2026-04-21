# Spec: issue-642 — design doc 38 drift: flip 38.1, 38.2, 38.4 to ✅ Present

## Design reference
- **Design doc**: `docs/design/38-qa-ci-gate.md`
- **Section**: `§ Future`
- **Implements**: 38.1 — qa.md §3a: gh pr checks (🔲 → ✅)
- N/A — infrastructure change (design doc drift fix, no new behavior)

---

## Zone 1 — Obligations

**O1** — `docs/design/38-qa-ci-gate.md` Present section reflects actual qa.md implementation: 38.1 (`gh pr checks` in §3a), 38.2 (CI gate in `_merge_pr`), 38.4 (DCO mechanical fix) are all present in qa.md and must be marked ✅.

**O2** — 38.3 and 38.5 remain 🔲 (CI fix loop and flaky check retry are not yet implemented as executable code — only `[AI-STEP]` comments).

**O3** — scripts/validate.sh PASSED, scripts/lint.sh PASSED.

---

## Zone 2 — Implementer's judgment
- This is a design doc drift fix. No code changes.
- Verify each 38.x against qa.md before marking ✅.

---

## Zone 3 — Scoped out
- Implementing 38.3/38.5 (separate issues).
