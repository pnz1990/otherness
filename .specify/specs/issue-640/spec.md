# Spec: issue-640 — COORD §1b: Vision Pressure Set (36.1)

## Design reference
- **Design doc**: `docs/design/36-vision-pressure-in-coord.md`
- **Section**: `§ Future`
- **Implements**: 36.1 — COORD §1b: build in-memory vision pressure set (🔲 → ✅)

---

## Zone 1 — Obligations

**O1** — At session start (after §1b-sim, before §1c), COORD reads `docs/design/*.md` and builds `VISION_PRESSURE_SET`: a list of the first 40 chars (lowercased) of each `🔲 Future` item in every design doc. The set is an environment variable (exported) for downstream use in §1e.

**O2** — The vision pressure set is built with graceful fallback: if `docs/design/` does not exist or is empty, `VISION_PRESSURE_SET` is set to an empty string and the session proceeds normally.

**O3** — The build is logged: `[COORD §1b-vision] Vision pressure set: N items from M design docs.`

**O4** — scripts/validate.sh PASSED, scripts/lint.sh PASSED.

---

## Zone 2 — Implementer's judgment

- Implementation location: new `## 1b-vision` section in coord.md, between §1b-sim and §1c.
- `VISION_PRESSURE_SET` exported as newline-separated list (or comma-separated) for use in §1e claim logic.
- This PR implements 36.1 only (set building). §36.2 (boost in §1e) is a separate issue.

---

## Zone 3 — Scoped out

- 36.2 (claim priority boost), 36.3 (log claim decisions), 36.4 (vision-effective queue depth), 36.5 (SM report), 36.6 (dedup) — separate items.
