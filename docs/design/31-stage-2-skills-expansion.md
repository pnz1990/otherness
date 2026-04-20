# 31: Stage 2 — Skills Expansion

> Status: Complete | Created: 2026-04-20

---

## What this does

Grows the skills library from 4 foundational skills to ≥10 through `/otherness.learn`
sessions on high-signal open-source repos. Skills are reusable agent checklists that
improve decision quality across all projects.

---

## Present (✅)

- ✅ `/otherness.learn` command deployed — `agents/otherness.learn.md` + `.opencode/command/otherness.learn.md` (2026-04-14)
- ✅ Skills library reached ≥10: currently 12 skills in `agents/skills/` (2026-04-20)
- ✅ `PROVENANCE.md` — audit trail for each learning session: what was learned, what was rejected, why (2026-04-14)
- ✅ `agents/skills/README.md` — skill index listing all skills and when to load them (2026-04-14)
- ✅ SM §4c: autonomous learn scheduling — SM runs `/otherness.learn` when Type B rate drops; monitors skill quality (2026-04-14)
- ✅ Quality gate enforced: skills are specific, falsifiable, novel, transferable — PROVENANCE.md records rejections (2026-04-14)

## Future (🔲)

*(Stage 2 is complete. All deliverables shipped.)*

---

## Zone 1 — Obligations

**O1 — Skills library has ≥10 skills at all times.**
If a skill is deprecated, a replacement must be added in the same batch.
Current count: 12.

**O2 — Every new skill has a PROVENANCE.md entry.**
The entry records: what pattern was observed, what skill was created or extended,
and what was rejected.

**O3 — Skills are generic — no project names.**
Skills must be transferable to any project. PROVENANCE.md records project-specific
rejections to keep skills portable.

---

## Zone 2 — Implementer's judgment

- Skills are grown through `/otherness.learn` sessions, not through direct file editing.
- The SM §4c cycle ensures automatic growth when needed.

---

## Zone 3 — Scoped out

- Automated skill quality scoring
- Cross-project skill effectiveness tracking
