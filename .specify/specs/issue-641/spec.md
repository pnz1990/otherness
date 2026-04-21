# Spec: issue-641 — vibe-vision-auto.md SCAN 5: read current pressure block (37.1)

## Design reference
- **Design doc**: `docs/design/37-self-updating-pressure-prompts.md`
- **Section**: `§ Future — 37.1`
- **Implements**: SCAN 5 reads the active pressure block by parsing specifically the `prompt:` YAML section of the Step A workflow step in `.github/workflows/otherness-scheduled.yml`, extracting the `Context for this vision scan:` block.

---

## Zone 1 — Obligations (falsifiable)

**O1** — SCAN 5's Step 1 reads the `prompt:` YAML key from the Step A step in `.github/workflows/otherness-scheduled.yml` (identified by containing `vibe-vision-auto.md`). Violation: SCAN 5 reads a different field or searches generic text.

**O2** — SCAN 5 extracts the full text between `Context for this vision scan:` and `For each gap you identify` (or end of block). This full text is stored in `pressure_block` (string) and `pressure_keywords` (list of key phrases). Violation: only keywords extracted with no raw block stored.

**O3** — If `.github/workflows/otherness-scheduled.yml` does not exist, SCAN 5 gracefully falls back to searching all `.github/workflows/*.yml` files for `Context for this vision scan:`. Logs: `[SCAN 5] Falling back to workflow scan (otherness-scheduled.yml not found)`. Violation: SCAN 5 crashes or silently skips when file is absent.

**O4** — If no pressure block is found in any workflow file, SCAN 5 logs `[SCAN 5] No pressure block found — skipping.` and exits cleanly. Violation: SCAN 5 raises an exception.

**O5** — `pressure_block` and `pressure_keywords` are available to the subsequent scoring step (Steps 2+). They are not discarded after Step 1. Violation: Steps 2+ cannot access the block text from Step 1.

---

## Zone 2 — Implementer's judgment

- The YAML parsing for `prompt:` doesn't require a full YAML parser — a regex/line-based approach is sufficient. The workflow file is known-format (otherness-owned).
- The Step A step is identified by its `prompt:` content containing `vibe-vision-auto.md`. This is the authoritative marker.
- The pressure block delimiter `Context for this vision scan:` is the primary marker; `OTHERNESS_PRESSURE_START/END` is an optional alternative marker already in the code.
- The existing SCAN 5 code partially does this. The change is: prefer `otherness-scheduled.yml` → Step A's `prompt:` field, fall back to generic workflow search only if that fails.

---

## Zone 3 — Scoped out

- SCAN 5 step 37.2 (scoring), 37.3 (rewrite condition), 37.4 (synthesise new block), 37.5 (update workflow) — separate issues.
- Cross-project pressure propagation (37.6) — design doc 37 §Zone 3.
- YAML full-parse of the workflow (overkill for this use case).
