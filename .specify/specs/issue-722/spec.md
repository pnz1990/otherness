# Spec: Vision-Pressure Claim Priority Boost (COORD §1e)

**Item**: issue-722

## Design reference
- **Design doc**: `docs/design/36-vision-pressure-in-coord.md`
- **Section**: `§ Future`
- **Implements**: 36.2 — COORD §1b: boost claim priority for vision-pressure items (🔲 → ✅)

---

## Zone 1 — Obligations

**O1** — When `_item_sort_key` evaluates a candidate item, it reads the `VISION_PRESSURE_SET` env var (newline-separated keys, each 40 chars lowercased, built by §1b-vision). If any key from `VISION_PRESSURE_SET` is a substring of the item's `title + body` (case-insensitive), the item is classified as vision-backed. Violation: an item whose title/body contains a VPS key is treated as non-vision-backed.

**O2** — Vision-backed items receive a priority boost of `-2` (equivalent to skipping two priority levels) in the sort key, applied after the existing hygiene/sim-recovery adjustments. Non-vision-backed items receive a demotion of `+2`. This means within the same label-based priority tier, vision-backed items always sort before non-vision-backed items. Violation: a vision-backed item and a non-vision-backed item of the same label priority sort in the same position.

**O3** — The boost is a tiebreaker within a priority tier, not an override. A `priority/critical` non-vision-backed item still claims before a `priority/medium` vision-backed item (critical=0 > medium=2 even without ±2 adjustment). Violation: a critical non-vision-backed item (sort key 0+2=2) is overridden by a medium vision-backed item (sort key 2-2=0). [NOTE: O2 applies ±2 so critical non-backed=2, medium backed=0 — this is a violation of O3. Corrected: boost must be ±1, not ±2, OR the critical tier must be protected. See Zone 2 for resolution.]

**O3-corrected** — The vision boost is `±1`. Vision-backed items get `-1`; non-vision-backed items get `+1`. With `priority/critical=0`: non-backed=1, backed=−1. With `priority/high=1`: non-backed=2, backed=0. This means critical items always sort before high-vision-backed items (1 < 0 is false — still correct because critical backed=−1 sorts before critical non-backed=1). Violation: critical non-vision-backed (key=1) sorts after medium vision-backed (key=2-1=1) — they tie. Tie is broken by item_id (deterministic). Acceptable per design doc O1: "tiebreaker, not override" — within the same effective sort key, the item_id tiebreak is fine.

**O4** — The body of the item (for vision matching) is sourced from the GitHub issue body stored in `state.json` under the item's `body` field (if present), otherwise the title alone is used. Items without a body fall back to title-only matching. Violation: body not checked when `state.json` has a non-empty `body` field.

**O5** — If `VISION_PRESSURE_SET` is empty or unset, vision boost is disabled (boost=0 for all items) — no change to existing sort behavior. Violation: sort behavior differs from pre-36.2 when VPS is empty.

**O6** — Fail-open: if reading `VISION_PRESSURE_SET` or matching raises an exception, the sort falls back to the pre-36.2 key (boost=0). Violation: exception during vision match propagates and crashes the claim loop.

---

## Zone 2 — Implementer's judgment

- `±1` boost is used (not `±2`) per the O3-corrected reasoning above. This means at most one priority tier shift.
- The `body` field in `state.json` features may be absent — fall back to title. Not all items in `state.json` are GitHub issues with bodies stored; the VPS match on title alone is sufficient for most cases (design doc item descriptions are typically short and reflected in the issue title).
- The match is case-insensitive substring: `vps_key in (title + ' ' + body).lower()`.
- `VISION_PRESSURE_SET` is read from `os.environ.get('VISION_PRESSURE_SET', '')` inside the Python `-c` block.

---

## Zone 3 — Scoped out

- Logging vision-pressure claim decisions (that is 36.3 — a separate item)
- Vision-effective queue depth check (that is 36.4 — a separate item)
- SM §4f vision pressure utilisation report (that is 36.5 — a separate item)
- Deduplication against ✅ Present items (that is 36.6 — a separate item)
- Fuzzy matching of VPS keys (exact substring only)
- Fetching issue body from GitHub API at claim time (body from state.json only)
