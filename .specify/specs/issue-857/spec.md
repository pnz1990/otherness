# Spec: issue-857

## Design reference
- **Design doc**: `docs/design/36-vision-pressure-in-coord.md`
- **Section**: `§ Future`
- **Implements**: 36.3 — COORD §1b: log vision-pressure claim decisions (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — After each claim, a log line is posted to REPORT_ISSUE.**
The log line format: `[COORD §36.3 | <session_id>] Claimed #<N> [vision-backed: yes/no] — <reason>`
Where `<reason>` is one of: `vision-backed: matched VPS key '<key>'` or `vision-backed: no — no VPS key match`.
- Verify: `grep -q 'COORD §36.3' agents/phases/coord.md`

**O2 — The log call is non-blocking (|| true).**
A failure to post the comment must not stop the claim or the loop.
- Verify: `grep -A3 'COORD §36.3' agents/phases/coord.md | grep -q '|| true'`

**O3 — The reason identifies which VPS key matched (or states no match).**
When vision-backed=yes, the reason includes the specific key that matched.
When vision-backed=no, the reason states no VPS key match.
- Verify: `grep -A5 'COORD §36.3' agents/phases/coord.md | grep -q 'matched VPS key\|no VPS key match'`

**O4 — Design doc 36.3 flipped from 🔲 to ✅.**
- Verify: `grep -q '✅ 36.3' docs/design/36-vision-pressure-in-coord.md`

---

## Zone 2 — Implementer's judgment

- Place the log call immediately after the existing §36.5 vision-backed tracking block.
- Reuse the `_VPS_MATCH` and `_VPS_KEY` variables from §36.5 — compute the matched key once.
- Use `gh issue comment` for report visibility; the terminal echo already exists from §36.5.
- Keep the log message short (one line).

---

## Zone 3 — Scoped out

- Modifying anything outside coord.md and docs/design/36-vision-pressure-in-coord.md
- Storing the log in state.json (36.5 already tracks counts)
- Retroactively logging previous claims
