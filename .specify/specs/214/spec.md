# Spec: /otherness.vibe-vision — validate and wire

> Item: 214 | Created: 2026-04-18 | Status: Active

## Design reference
- **Design doc**: `docs/design/05-vibe-vision.md`
- **Section**: `## Future`
- **Implements**: /otherness.vibe-vision command + dialogue protocol + artifact cascade (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — `/otherness.vibe-vision` appears in the README command table.**
The README primary command table must list `/otherness.vibe-vision` with its purpose.

Behavior that violates this: README command table exists but does not include
`/otherness.vibe-vision`.

**O2 — `definition-of-done.md` includes Journey 6.**
`docs/aide/definition-of-done.md` must include a Journey 6 that validates:
- A vibe-vision session produces at least one `docs/design/` stub with at least one
  `🔲 Future` item in the correct format
- COORD on the next startup finds those Future items and generates queue issues from them
- No human intervention required after the vibe-vision session itself (for the artifact
  landing, not the dialogue)

Behavior that violates this: Journey 6 is absent from definition-of-done.md.

**O3 — Design doc 05 marks all 5 Future items as ✅ Present.**
`docs/design/05-vibe-vision.md` must move all 5 `🔲 Future` items to `✅ Present`,
with a PR reference for each.

Behavior that violates this: any `🔲 Future` item remains in design doc 05 after
this PR merges.

**O4 — `agents/vibe-vision.md` has the correct MODE: VISION block.**
The file must begin with `## MODE: VISION` before any other section (after frontmatter).
This is already present — QA must verify it has not been removed or corrupted.

Behavior that violates this: MODE block absent, or MODE is IMPLEMENT or READ-ONLY.

---

## Zone 2 — Implementer's judgment

- Whether to add hardening changes to agents/vibe-vision.md: CRITICAL tier file — any
  change requires needs-human. Keep changes minimal. If no hardening is needed beyond
  what already exists, do not touch agents/vibe-vision.md in this PR.
- How to phrase Journey 6: keep it consistent with existing journey format. Exact steps
  must be verifiable with `gh` and `ls` commands, same as other journeys.
- Where to place Journey 6 in definition-of-done.md: after Journey 5, before the status
  table.

---

## Zone 3 — Scoped out

- Actually running a vibe-vision dialogue session (requires human participant)
- Testing the artifact cascade end-to-end against a live project
- Changes to agents/vibe-vision.md (CRITICAL tier — separate item if needed)
