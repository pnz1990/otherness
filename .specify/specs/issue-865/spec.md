# Spec: issue-865 — Vision scan gap stagnation ratio (42.2)

## Design reference
- **Design doc**: `docs/design/42-vision-scan-to-shipped-gap.md`
- **Section**: `§ Future`
- **Implements**: 42.2 — Gap stagnation ratio reporting (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — Each SCAN run must track three counters:**
- `new_gaps` = count of `⚠️ Inferred` items written this run (items added to design docs)
- `gaps_aged_30d` = count of open `⚠️ Inferred` GitHub issues older than 30 days with
  no corresponding closed issue (stale gaps not being worked on)
- `gaps_shipped` = count of items promoted from 🔲 → ✅ this run

**O2 — Stagnation ratio computed as `gaps_aged_30d / (new_gaps + gaps_shipped)`**
Division by zero case: if `(new_gaps + gaps_shipped) == 0`, treat ratio as N/A
(report `gaps_aged_30d` count but do not compute ratio). Do NOT divide by zero.

**O3 — If stagnation ratio > 2.0: include `[⚠️ GAP STAGNATION: N old gaps are not shipping]`**
The report issue comment posted at the end of the scan must include this message
when `gaps_aged_30d / (new_gaps + gaps_shipped) > 2.0`. The message must name N
(the count of `gaps_aged_30d`).

**O4 — Stagnation metrics are always reported, not just when threshold exceeded**
The report comment must always include a line like:
`Gap stagnation: new=X shipped=Y aged_30d=Z ratio=N.N`
even when the ratio is below 2.0 (for observability).

---

## Zone 2 — Implementer's judgment

- Where to compute: after all SCAN phases complete (between SCAN 5 and COMMIT section).
- `gaps_aged_30d`: query `gh issue list` with `--search "⚠️ Inferred"` and filter by age.
- `new_gaps` and `gaps_shipped`: track via git diff at commit time (count `⚠️ Inferred` lines
  added vs `🔲 → ✅` transitions).
- The stagnation signal is appended to the `$SUMMARY` variable used in the report comment.

---

## Zone 3 — Scoped out

- Writing gap_stagnation_ratio to state.json (that is 42.3 — a separate issue)
- Cross-project aggregation
- Automatic priority adjustment in COORD (42.3)
