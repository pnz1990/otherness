# Spec: Spatially diverse queue generation + AREA_TO_SPACES config

> Items: 299, 300 | Created: 2026-04-19 | Status: Active

## Design reference
- **Design doc**: `docs/design/15-multi-session-spatial-coordination.md`
- **Implements**: coord.md §1c spatial diversity in queue gen + AREA_TO_SPACES config (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — coord.md §1c queue generation adds a spatial diversity preference.**
When generating N items from design doc Future items, the queue gen [AI-STEP] prefers
selecting items from different area labels. If all remaining items are the same area:
select the first one (no deadlock). This is a preference, not a hard constraint.

**O2 — AREA_TO_SPACES is configurable in otherness-config.yaml.**
A new optional `maqa.area_file_spaces` key in otherness-config.yaml allows
project-specific customization. The coord.md [AI-STEP] reads this key if present;
falls back to the hardcoded AREA_TO_SPACES map if absent.

**O3 — Design doc 15 marks these items ✅ Present.**

---

## Zone 2 — Implementer's judgment

- Both changes are [AI-STEP] comments only — CRITICAL-B.
- The AREA_TO_SPACES config key in otherness-config-template.yaml should be
  commented out by default (opt-in customization).

---

## Zone 3 — Scoped out

- Enforcing spatial diversity (preference only, no hard block)
- Cross-project area_file_spaces sharing
