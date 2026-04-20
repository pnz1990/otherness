# Spec: validate.sh — ⚠️ Inferred item source attribution check

## Design reference
- **Design doc**: `docs/design/00-marker-conventions.md`
- **Section**: `§ Future`
- **Implements**: validate.sh check for ⚠️ Inferred item source attribution format (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1** — `scripts/validate.sh` adds a new check [7/N] that scans all `docs/design/*.md` files for lines matching `^- 🔲 ⚠️ Inferred:` or `^- 🔲 ⚠️ Observed:`.

**O2** — Each such line must end with a parenthetical attribution matching the pattern `(source, YYYY-MM-DD)` where source is one of: `autonomous-vision`, `pm-§5c`, `pm-§5h`, or any non-empty string. A violation is: the line does not end with `(<something>, <date>)`.

**O3** — If any ⚠️ Inferred/Observed item lacks source attribution, `validate.sh` exits with code 1 and prints `ERROR: ⚠️ Inferred item missing attribution: <file>:<item>`.

**O4** — If no ⚠️ Inferred/Observed items are found (or all have attribution), the check exits 0 and prints `OK: all ⚠️ Inferred items have source attribution`.

**O5** — Items inside fenced code blocks (``` ``` ```) are NOT checked — they are documentation examples (e.g., in `00-marker-conventions.md` Future section template). Only real list items outside code blocks are checked.

**O6** — `bash scripts/validate.sh` and `bash scripts/test.sh` both exit 0 after this change.

---

## Zone 2 — Implementer's judgment

- Whether to use Python or bash for the check: Python is preferred (consistent with other checks in validate.sh).
- The exact attribution pattern: `\(.*,\s*\d{4}-\d{2}-\d{2}\)` at end of line. Flexible enough for any source name.
- Whether the check is [7/6] or [7/7]: update the check numbering to reflect total.

---

## Zone 3 — Scoped out

- Checking ⚠️ Observed items in docs/aide/ (not in scope — only docs/design/)
- Retroactively adding attribution to any existing items (zero such items exist as of 2026-04-20)
- Checking attribution format in PROVENANCE.md or other non-design docs
