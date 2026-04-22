# Spec: PM §5k README refresh PR duplicate suppression

## Design reference
- **Design doc**: `docs/design/39-autonomous-readme-refresh.md`
- **Section**: `§ Future`
- **Implements**: 39.4 — PM §5k duplicate suppression (🔲 → ✅)

---

## Zone 1 — Obligations

**O1** — PM §5k must check for an existing open README refresh PR (title starting with
`docs(readme): refresh`) before creating a new one. At most one open at a time.

_Violation_: Multiple `docs(readme): refresh` PRs exist simultaneously in the open state.

---

## Zone 2 — Implementer's judgment

The implementation at `agents/phases/pm.md` line ~1707 already satisfies O1 via the
`REFRESH_TITLE_PREFIX` check. This item is a doc-drift fix: the implementation exists
but the design doc item was not flipped to ✅. This PR records the as-built status.

---

## Zone 3 — Scoped out

- Adding the duplicate suppression (already implemented)
- Age-based follow-up comment (already implemented at line ~1724)
