# Spec: feat(qa): enforce customer doc existence for user-visible features

> Item: 159 | Risk: medium | Size: s | Tier: CRITICAL (qa.md)

## Design reference
- **Design doc**: `docs/design/01-declarative-design-driven-development.md`
- **Section**: `§ Future (🔲)`
- **Implements**: Customer doc requirement enforced by QA (🔲 → ✅)

---

## Zone 1 — Obligations

**O1**: The QA spec conformance check (§3b) must include a step that checks for a customer doc when the spec has a non-N/A `## Design reference`.
- **Falsified by**: QA approves a PR with a non-N/A design reference without checking for a customer doc.

**O2**: The check must be a **MISS** finding (open a follow-up issue, do NOT block merge). Since "user-visible" is ambiguous, blocking would cause false positives.
- **Falsified by**: The check blocks merge for any PR with a non-N/A design reference.

**O3**: The check must only fire when the design reference points to an actual `docs/design/` file (not N/A). Infra-only items must be skipped.
- **Falsified by**: The check fires for specs with `## Design reference: - N/A`.

**O4**: The change must be a 3-5 line addition to qa.md §3b — no restructuring.
- **Falsified by**: More than 8 lines of qa.md changed.

**O5**: `docs/design/01-DDDD.md` `## Future` must be updated: `🔲 Customer doc requirement enforced by QA` → `✅ Present`.
- **Falsified by**: Item still in Future after merge.

---

## Zone 2 — Implementer's judgment

- What constitutes a "customer doc": `docs/<feature-area>.md` where feature-area is derived from the design doc filename or referenced section.
- Since this is a MISS (not WRONG), wording should be informational: "Consider adding a customer doc..."

---

## Zone 3 — Scoped out

- Does NOT enforce customer doc content quality
- Does NOT check whether the customer doc is up-to-date
- Does NOT block merge — MISS only
