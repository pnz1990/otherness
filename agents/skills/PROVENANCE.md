# otherness Learning Provenance Log

This file records every `/otherness.learn` session: what was studied, what was extracted,
and what was rejected. It prevents re-studying the same material and provides an audit trail
for every skill update.

---

## 2026-04-14 — ellistarn/home + ellistarn/muse (manual import)

**Files read:**
- `.skills/declaring-designs/SKILL.md`
- `.skills/reconciling-implementations/SKILL.md`
- `muse.md` (author's personal muse — epistemic standards section)
- `designs/001-the-muse.md`
- `designs/002-grammar.md`
- `designs/009-observations.md`

**Patterns extracted:** 4

**Disposition:**
- `declaring-designs` → NEW_SKILL (`agents/skills/declaring-designs.md`)
  Three-zone model (obligations / judgment / scoped out) + eleven spec quality properties.
  Directly applicable to the otherness Phase 2a spec-writing step. Wired into standalone.md.

- `reconciling-implementations` → NEW_SKILL (`agents/skills/reconciling-implementations.md`)
  Correctness > Performance > Observability > Testing > Simplicity priority ordering + per-dimension
  checklists + gap classification (WRONG / STALE / SMELL / MISS). Replaces vague QA instructions
  in standalone.md Phase 3. Wired in.

- `gap-classification` → AGENT_LOOP (standalone.md Phase 3)
  "Implementation is wrong (fix code) or design is stale (surface to human)" — explicit
  classification before acting on any divergence. Added to Phase 3 instructions.

- `muse-integration` → README + optional dependency
  muse.md as OpenCode instruction calibrates agent judgment to the project owner's specific
  reasoning patterns. Added as optional dependency section in README.

**Rejected patterns (with reason):**
- `muse distillation pipeline` — not transferable: muse's observe/compose/ask operations are
  domain-specific to personal-muse generation, not generic to agent workflows.
- `grammar-driven system design` — not transferable at this time: the formal typing discipline
  (Conversation / Observation / Muse as types with operations) is valuable but requires
  deeper project-level work to adapt. File as future learning item.
- `observations pipeline concurrency model` — not transferable: the upload-channel / observe-channel
  pipeline architecture is specific to muse's data ingestion problem, not to otherness workflows.
