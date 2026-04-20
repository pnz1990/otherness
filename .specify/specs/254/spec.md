# Spec: PM §5i README/AGENTS.md Claims Cross-Check

## Design reference
- **Design doc**: `docs/design/04-documentation-health.md`
- **Section**: `§ Zone 1 — O5: Claims in README and AGENTS.md are verified periodically`
- **Implements**: O5 machine-checkable claims verification (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1** — `agents/phases/pm.md §5i` must contain executable python3 code (not `[AI-STEP]` comments) that: (a) checks README command files exist, (b) checks AGENTS.md Package Layout files exist, (c) checks validate.sh step count vs AGENTS.md claim, (d) checks BUILD/TEST/LINT scripts exist. Violation: §5i contains only comments.

**O2** — All findings use duplicate suppression (`open_if_absent` pattern). Violation: running §5i twice on same repo opens duplicate issues.

**O3** — Graceful fallback: if README.md or AGENTS.md is missing/unreadable, §5i logs a warning and continues (does not crash). Violation: exception propagates and halts PM phase.

**O4** — `docs/design/04-documentation-health.md` Present section includes this item with a PR reference. Violation: PR reference absent.

**O5** — All validate and lint checks pass. Violation: non-zero exit.

---

## Zone 2 — Implementer's judgment

- Package Layout check only verifies known relative paths (agents/, docs/, scripts/, .opencode/) — not `~/.otherness` paths which are deployment-specific.
- Step count check: looks for `[N/N]` pattern in validate.sh echo statements; if 0 found, skips the comparison.

---

## Zone 3 — Scoped out

- Automated code analysis (AST parsing) — prose matching only
- Cross-checking code comments or docstrings against documentation
- Verifying claim accuracy for other markdown files outside README/AGENTS.md
