# Spec: issue-891 — COORD §1f queue-depth check accounts for vision pressure (36.4)

## Design reference
- **Design doc**: `docs/design/36-vision-pressure-in-coord.md`
- **Section**: `§ Future`
- **Implements**: 36.4 — COORD §1f queue-depth check accounts for vision pressure (🔲 → ✅)

## Zone 1 — Obligations (falsifiable)

O1. The queue-depth learn/vision trigger in COORD §1e (empty-queue block) MUST count
    only vision-backed todo items when deciding whether to trigger learn.
    Violation: trigger fires when 10 chore-only items exist but 0 vision-backed items exist,
    but also fires when 5+ vision-backed items exist (false positive).

O2. "Vision-backed" is defined as: a todo item whose title or issue body contains a substring
    matching any key from `VISION_PRESSURE_SET` (already built by §1b-vision).
    If `VISION_PRESSURE_SET` is empty or unset: fail-open — count ALL todo items (preserve
    existing behavior; no regression when VPS is unavailable).
    Violation: trigger logic errors when VISION_PRESSURE_SET is unset.

O3. The check MUST log: "[COORD §1e-36.4] Vision-backed todo items: N / M total."
    Violation: no log line containing "Vision-backed todo items" appears.

O4. The minimum queue depth guard at §1f (QUEUE_REMAINING < 5 → trigger queue-gen)
    MUST also be updated to count vision-backed items.
    Violation: guard still uses raw QUEUE_REMAINING without VPS filtering.

O5. `scripts/validate.sh` MUST PASS after the change.
    Violation: any validate check fails.

O6. `scripts/lint.sh` MUST PASS after the change.
    Violation: lint fails.

## Zone 2 — Implementer's judgment

- Whether to implement O4 (§1f guard) in this PR or leave for 36.5 follow-up
- Exact threshold for "vision-backed queue low" (default: 3 vision-backed items triggers)
- Whether the VPS key match uses the issue number or the title text

## Zone 3 — Scoped out

- Changing the VISION_PRESSURE_SET build logic (that's §36.1, already done)
- Logging claim decisions in batch report (that's §36.3)
- SM health comment vision pressure utilisation (that's §36.5)
- The §1f minimum queue depth guard deep refactor (scope too large for this item)
