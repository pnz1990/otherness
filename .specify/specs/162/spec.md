# Spec: fix(coord): is_done filter too broad

> Item: 162 | Risk: medium | Size: s | Tier: CRITICAL (coord.md — phases/*.md)

## Design reference
- N/A — bug fix with no user-visible behavior change (agents/phases/coord.md)

---

## Zone 1 — Obligations

**O1**: The `is_done` function in coord.md queue generation must require the matching key to be at least 15 characters before using substring matching against merged PR titles.
- **Falsified by**: A 5-character key like `onboard` causes a design doc item to be skipped because `onboard` appears in unrelated PR titles.

**O2**: Items that should not be filtered must appear in the queue after the fix. Specifically, the `/otherness.onboard generates design doc drafts` item must not be filtered based on the string `/otherness.onboard` appearing in PR titles.
- **Falsified by**: Running queue generation still filters the onboarding item when it has not been implemented.

**O3**: Items that ARE genuinely done (title appears in state.json done items or PR titles as a long, specific description) must still be filtered correctly.
- **Falsified by**: A previously-done item reappears in the queue.

**O4**: Change is confined to the `is_done` function in coord.md — no other logic changed.
- **Falsified by**: Other parts of coord.md modified.

---

## Zone 2 — Implementer's judgment

- Minimum key length for substring matching: 15 characters
- Fallback when key is short (<15 chars): use the full description for matching instead

---

## Zone 3 — Scoped out

- Does NOT change the overall queue generation logic
- Does NOT fix any design doc content
