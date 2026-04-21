# Spec: SM §4f post AMBER note when vision-misaligned

## Design reference
- **Design doc**: `docs/design/35-vision-alignment-signal.md`
- **Section**: `§ Future`
- **Implements**: 35.2 — SM §4f: post AMBER note when vision-misaligned: include in health comment "⚠️ 0 vision-aligned PRs this session. Queue may have drifted from design docs. Run vibe-vision or check coord §1b." (🔲 → ✅)

---

## Zone 1 — Obligations

**O1** — When `VISION_PR_COUNT == 0` (0 design-doc-backed PRs merged this session), the SM §4f health comment must include the specific note: "⚠️ 0 vision-aligned PRs this session. Queue may have drifted from design docs. Run /otherness.vibe-vision or check coord §1b."
- Violation: the note is absent from the health comment when VISION_PR_COUNT == 0.

**O2** — The note must appear inside the health comment (not as a separate API call).
- Violation: the note is posted as a separate `gh issue comment` call.

**O3** — The note must not appear when VISION_PR_COUNT > 0.
- Violation: note shown even when vision-aligned PRs were merged.

---

## Zone 2 — Implementer's judgment

- Append the note to the `THROUGHPUT_WARN` variable (already included in the health comment body).
- The existing `THROUGHPUT_WARN` format is: `"⚠️ ${SESSION_OUTCOME} session (${VISION_PR_COUNT} vision-aligned PRs)"`. Extend it with the actionable guidance.

---

## Zone 3 — Scoped out

- N/A — infrastructure change with no user-visible behavior beyond the health comment text.
