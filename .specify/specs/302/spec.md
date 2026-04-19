# Spec: Journey 2 AMBER/RED escalation + test.sh 5b reason

> Items: 302, 303 | Created: 2026-04-19 | Status: Active

## Design reference
- **Design doc**: `docs/design/16-journey-2-reference-project.md`
- **Implements**: PM §5g Journey 2 escalation + test.sh check 5b reason (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — PM §5g health computation considers Journey 2 failure duration.**
If Journey 2 has been failing for >24h: health is AMBER (regardless of other signals).
If >72h: health is RED (requires human judgment).
This extends the PM §5g [AI-STEP] that already exists for other health signals.

**O2 — test.sh check 5b outputs the specific reason for failure.**
Currently check 5b outputs only PASS/FAIL. It must also output the specific stall
duration (e.g. "alibi _state last commit 5d ago") for PM to use in health computation.

**O3 — Design doc 16 marks these items ✅ Present.**

---

## Zone 2 — Implementer's judgment

- test.sh change: add a `--reason` output format (echo the age alongside PASS/FAIL).
- PM §5g change: read the reason from test.sh 5b and incorporate into AMBER/RED logic.
- Both changes are [AI-STEP] additions — CRITICAL-B.

---

## Zone 3 — Scoped out

- Automated restart of the reference project (human action required for RED)
- Per-project configurable AMBER/RED thresholds
