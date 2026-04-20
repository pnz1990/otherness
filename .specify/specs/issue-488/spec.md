# Spec: Batch stale marker cleanup + sm.md dotdir glob fix

## Design reference
- **Design doc**: `docs/design/27-security-model.md`
- **Section**: `## Future`
- **Implements**: N/A — infrastructure cleanup (stale markers removal, scanner improvement)
  Note: M5b item is explicitly DEFERRED and not implemented in this PR.

---

## Zone 1 — Obligations

**O1 — All false-positive ⚠️ Stale markers removed from design docs.**
Files confirmed to exist must have their stale markers removed. Files confirmed missing
(scripts/vision.md, .github/workflows/e2e.yml) keep their markers.

**O2 — sm.md §4g glob fallback extended to check .github/ directory.**
The `glob.glob(f'**/{fref}', recursive=True)` does not traverse dotdirs. Add a second
glob: `glob.glob(f'.github/**/{fref}', recursive=True)` to catch workflow files.

**O3 — validate.sh and lint.sh still pass after changes.**

---

## Zone 2 — Implementer's judgment

- Docs 05, 06, 19, 20, 23, 24, 27, 28, 30, 31, 33 need stale markers removed
- docs 10 (scripts/vision.md) and 26 (e2e.yml) are genuinely missing — leave as-is
- sm.md patch: CRITICAL-A tier (modifies phases/sm.md with real code)

---

## Zone 3 — Scoped out

- Creating missing files (scripts/vision.md, e2e.yml) - out of scope for this cleanup
- Auditing other projects for stale markers
