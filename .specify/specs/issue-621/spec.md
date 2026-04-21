# Spec: issue-621 — otherness.learn.md: diversity-first learn target selection

## Design reference
- **Design doc**: `docs/design/35-quality-of-output-gaps.md`
- **Section**: `§ Future (implied by the monoculture problem description)`
- **Implements**: `agents/otherness.learn.md` §1b: when choosing repos to learn from (autonomous mode), score candidates by structural distance from existing skills — different language, different paradigm, different domain get higher scores. Document the scoring heuristic. The agent currently picks by quality/stars without considering architectural diversity.

---

## Zone 1 — Obligations (falsifiable)

**O1** — In §1b autonomous target selection, after gathering repo candidates from GitHub search, the agent sorts them by a diversity score (not just stars/quality) before selecting. Violation: selection order is purely by star count or first-match.

**O2** — The diversity scoring is based on: (a) skill category coverage in PROVENANCE.md (repositories from under-represented categories score higher), (b) language/paradigm distance from most recent 3 PROVENANCE.md entries. Violation: scoring ignores PROVENANCE.md.

**O3** — The diversity-first selection is always active in §1b (not only in frame-lock mode). `1b-arch-diverse` (frame-lock mode) uses a stronger version of the same mechanism. Violation: diversity scoring only triggers when `frame_lock_detected=true`.

**O4** — The scoring heuristic is documented in a comment block in §1b. A future agent reading it can understand how to reproduce the scoring. Violation: selection logic is implicit with no explanation.

**O5** — Graceful fallback: if PROVENANCE.md is absent or unreadable, the agent falls back to star-based selection without error. Violation: PROVENANCE.md absence causes crash.

---

## Zone 2 — Implementer's judgment

- The diversity scoring is lightweight: (a) read PROVENANCE.md category counts (same logic as `1b-arch-diverse`), (b) for each candidate repo, infer its likely paradigm category from name/description keywords, (c) repos in the least-represented category get +3 score, second-least +2, third-least +1. Stars/activity add up to +2. Max score 5.
- The sorting is done in the [AI-STEP] selection block, not as a bash script (this is a judgment step).
- `1b-arch-diverse` (frame-lock mode) remains separate but now explicitly documents it as the "diversity-first with hard override" variant of the same mechanism.
- The comment block documents: "DIVERSITY-FIRST SCORING: repos are scored by how different they are from existing PROVENANCE.md skills, not just by star count. This prevents the monoculture where all learned patterns come from similar agent-loop projects."

---

## Zone 3 — Scoped out

- Automated paradigm_category tagging in PROVENANCE.md — that is a separate issue (requires learn agent to write the field, then SM §4c to read it).
- Fuzzy semantic similarity of repo READMEs — keyword-based heuristic is sufficient.
- Cross-session target blacklisting (beyond what PROVENANCE.md already provides via "already studied" check).
