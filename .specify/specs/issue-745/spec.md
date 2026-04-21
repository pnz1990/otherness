# Spec: validate.sh check [8/8]: ✅ Present items referencing state.json fields must be verifiable

## Design reference
- **Design doc**: `docs/design/41-design-doc-integrity.md`
- **Section**: `§ Future`
- **Implements**: 41.3 — validate.sh check [8/8]: ✅ Present items referencing `state.json` fields are spot-checked against the local `.otherness/state.json` if present (🔲 → ✅)

---

## Zone 1 — Obligations

**O1** — `scripts/validate.sh` must have a new check labeled `[8/8]` that parses `docs/design/*.md` for ✅ Present items containing backtick-quoted `state.json` field references (e.g. `` `foo` field `` or ``write `foo` to state.json``).
- Violation: check is absent or unlabeled.

**O2** — For each identified field name, the check must verify whether the field key exists in `.otherness/state.json` on the local filesystem.
- Violation: check only does pattern matching without reading state.json.

**O3** — If `.otherness/state.json` does not exist locally (CI without _state): the check must skip gracefully (pass, not fail).
- Violation: check fails when state.json is absent.

**O4** — Missing fields must be logged as `[DOC-DRIFT]` warnings, not hard errors. The check must still pass (exit 0) with drift logged.
- Violation: check exits 1 on drift findings.

**O5** — The existing validate.sh check count (`[1/7]`...`[7/7]`) must be updated to `[1/8]`...`[8/8]`.
- Violation: new check is `[8/8]` but prior checks still say `[1/7]`...`[7/7]`.

---

## Zone 2 — Implementer's judgment

- Pattern for state.json field extraction: backtick-quoted word adjacent to "state.json" in ✅ Present items.
- The check is informational only (O4) — doc drift is a soft signal, not a hard gate.

---

## Zone 3 — Scoped out

- N/A — infrastructure change with no user-visible behavior.
