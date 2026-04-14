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

---

## 2026-04-14 — GitHub Trending (weekly) — automated learning session

**Repos studied:** 13 trending repos assessed; 4 read in depth
**Files read:**
- forrestchang/andrej-karpathy-skills: CLAUDE.md
- NousResearch/hermes-agent: AGENTS.md, README.md, skills/ directory listing
- multica-ai/multica: README.md
- coleam00/Archon: README.md

**Rejected (9 repos):** HKUDS/DeepTutor (domain-specific), microsoft/markitdown (utility),
google-ai-edge/gallery (ML deployment), thedotmack/claude-mem (insufficient content),
TapXWorld/ChinaTextbook (irrelevant), TheCraigHewitt/seomachine (domain-specific),
virattt/ai-hedge-fund (domain-specific), NVIDIA/personaplex (domain-specific),
jo-inc/camofox-browser (irrelevant)

**Patterns extracted:** 6

**Disposition:**
- `surgical-changes` → NEW_SKILL (agents/skills/agent-coding-discipline.md §Surgical Changes)
  "Touch only what the task requires. Do not improve adjacent code."
  Source: forrestchang/andrej-karpathy-skills CLAUDE.md

- `no-speculative-scope` → NEW_SKILL (agents/skills/agent-coding-discipline.md §No Speculative Scope)
  "Minimum code that satisfies the spec. No features beyond what was asked."
  Source: forrestchang/andrej-karpathy-skills CLAUDE.md

- `verifiable-goals` → NEW_SKILL (agents/skills/agent-coding-discipline.md §Verifiable Goals)
  "Transform task into concrete success criterion before starting."
  Source: forrestchang/andrej-karpathy-skills CLAUDE.md

- `human-approval-as-named-gate` → NEW_SKILL (agents/skills/autonomous-workflow-patterns.md)
  "Human approval is a planned gate in the workflow, not an emergency stop."
  Source: coleam00/Archon README.md

- `deterministic-vs-ai-nodes` → NEW_SKILL (agents/skills/autonomous-workflow-patterns.md)
  "Steps with deterministic outputs should be exact commands, not AI decisions."
  Source: coleam00/Archon README.md

- `single-registry-for-extension-points` → NEW_SKILL (agents/skills/autonomous-workflow-patterns.md)
  "Define extension points in one registry; derive all consumers automatically."
  Source: NousResearch/hermes-agent AGENTS.md

**Rejected patterns:**
- `prompt-caching-invariant` (hermes) — not transferable: specific to multi-turn conversation cost management
- `profile-safe-paths` (hermes) — already captured in otherness constitution IV
- `YAML-declarative-workflows` (Archon) — architecturally interesting but requires deep otherness redesign; deferred
- `context-fresh-per-iteration` (Archon) — captured as guideline in autonomous-workflow-patterns.md rather than new skill
- `multica-skills-lock` (multica) — interesting future enhancement for PROVENANCE.md machine-readability; deferred

**standalone.md changes:**
- Phase 2d: load agent-coding-discipline skill, add surgical changes and verifiable goals checkpoints
