# Spec: Fix hygiene scanner false positives for dotfile and subdirectory paths

## Design reference
- **Design doc**: `docs/design/29-continuous-code-hygiene.md`
- **Section**: `§ SM §4g hygiene scan — Check 1: Stale Present items`
- **Implements**: Bug fix — path resolution bug causes false-positive "stale" issues for
  files that exist at dotfile paths (`.opencode/`, `.specify/`) or in subdirectories (`scripts/`)

---

## Zone 1 — Obligations

**O1 — `fref.lstrip('./')` replaced with correct path normalization.**
The hygiene scanner must check file existence using the original path as-is (not stripped).
`os.path.exists(fref)` must be checked before concluding the file doesn't exist.

**O2 — Dotfile paths resolved correctly.**
A reference like `.opencode/command/otherness.upgrade.md` must resolve to
`.opencode/command/otherness.upgrade.md` (exists). The current `lstrip('./')` turns
`.opencode/...` into `opencode/...` (does not exist) — this must not happen.

**O3 — Subdirectory paths handled with glob fallback.**
A reference like `validate.sh` that exists at `scripts/validate.sh` must not trigger
a false positive. The scanner must use `glob.glob(f'**/{fref}', recursive=True)` as
a fallback when the bare path doesn't exist.

**O4 — The fix does not produce new false negatives.**
Files that genuinely do not exist must still be reported. The path fix must not
suppress true positives.

**O5 — Design docs 02, 03, 07 stale markers removed.**
The `⚠️ Stale — referenced file not found` markers in docs 02, 03, 07 must be
removed since the files do actually exist (the scanner was wrong, not the docs).

---

## Zone 2 — Implementer's judgment

- Whether to add `glob` import: yes — it's stdlib, no external dependency.
- Whether to normalize paths with `os.path.normpath`: use `os.path.exists(fref)` 
  directly — simpler and handles all cases correctly.
- Which files to remove stale markers from: all three flagged by issues #481, #482, #483.

---

## Zone 3 — Scoped out

- Adding a configurable ignore list for file references (not needed yet)
- Checking file references in Future/Planned sections (only Present items are checked)
- Checking that referenced files are non-empty (size check is separate hygiene concern)
