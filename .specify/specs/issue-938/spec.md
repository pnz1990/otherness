# Spec: COORD §1b-vision — Build VISION_PRESSURE_SET

## Design reference
- **Design doc**: `docs/design/36-vision-pressure-in-coord.md`
- **Section**: `§ Future`
- **Implements**: 36.1 — COORD §1b: build VISION_PRESSURE_SET at session start (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1** — COORD §1b must contain a `§1b-vision` block that reads all `🔲 Future` items
from `docs/design/*.md` and builds an in-memory set of vision pressure keys.
The set must be exported as `VISION_PRESSURE_SET` env var before §1c queue generation runs.

_Violation_: `VISION_PRESSURE_SET` is not exported by coord.md, or it is empty when
`docs/design/` contains files with `🔲 Future` items.

**O2** — The block must be fail-open: if `docs/design/` doesn't exist or any file fails to
parse, the block logs a warning and continues with an empty set.

_Violation_: coord.md crashes or exits when `docs/design/` is missing.

**O3** — The vision pressure set must use the first 40 chars (lowercased) of each `🔲 Future`
item description as a key. The export format must be newline-separated keys.

_Violation_: Keys are longer than 40 chars, not lowercased, or format is not newline-separated.

**O4** — The block must log: "Vision pressure set: N items from M design docs." after building.

_Violation_: No log message is printed after the build.

---

## Zone 2 — Implementer's judgment

- Where exactly in §1b to insert the block (before or after the vision.md check) is implementer's choice.
- Whether to use bash or Python for the build is implementer's choice; Python is preferred for robustness.
- The maximum number of items to include in VPS (capped at 40 per design doc, or total 200) is implementer's choice.

---

## Zone 3 — Scoped out

- Using VISION_PRESSURE_SET for claim priority boost (already implemented in §36.2 and §36.4)
- Persisting VISION_PRESSURE_SET to `_state` (explicitly not required — rebuilt each session)
