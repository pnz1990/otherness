# Spec: Gap fix cycle for docs/aide/ files

## Design reference
- **Design doc**: `docs/design/32-stage-3-onboarding-quality.md`
- **Section**: `## Future`
- **Implements**: Gap fix cycle: identify and fix any gaps in the generated `vision.md`, `roadmap.md`, `definition-of-done.md` (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — All docs/aide/ files pass check-onboarding.sh with 0 errors.**
After this fix cycle, `scripts/check-onboarding.sh` must exit 0 on the otherness repo.

**O2 — Journey numbering is sequential in definition-of-done.md.**
Journeys must appear in order: Journey 1, 2, 3, 4, 5, 6, 7, 8, Status.
No journey section may appear out of order.

**O3 — Design doc 32 Future item (Gap fix cycle) updated to ✅ Present.**
The 🔲 item must be promoted to ✅ with the current date.

---

## Zone 2 — Implementer's judgment

- Whether to change journey content (not just ordering): no — content is correct,
  only the ordering of sections 7 and 8 was wrong.
- Whether to run check-onboarding.sh as a test: yes, verifies O1.

---

## Zone 3 — Scoped out

- Auditing other projects' docs/aide/ files (out of scope for this repo item)
- Checking the quality of prose in vision.md (content quality is out of scope)
