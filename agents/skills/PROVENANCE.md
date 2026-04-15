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

---

## 2026-04-14 — crewAIInc/crewAI (automated learn session, issue #21)

**Files read:**
- `README.md` (full — 48,000 chars)
- `docs.crewai.com` — Crews vs Flows architecture overview

**Repos assessed:** 3 (microsoft/autogen — maintenance mode, less signal; langchain-ai/langchain — too broad; crewAIInc/crewAI — highest signal for this session)

**Patterns extracted:** 3

**Disposition:**

- `autonomy-precision-spectrum` → EXTENDED_SKILL (agents/skills/autonomous-workflow-patterns.md §Autonomy-Precision Spectrum)
  Crews (autonomous, uncertain path) vs Flows (precise, event-driven). Key insight: choose per step, not per system. Maps directly to otherness's coordinator (flow-like) vs engineer/QA (crew-like) phases. Added with concrete otherness-specific routing pattern.

- `conditional-routing-on-state` → EXTENDED_SKILL (agents/skills/autonomous-workflow-patterns.md §Conditional Routing on State)
  Route on structured state values (confidence level, counts), not just binary pass/fail. Directly applicable to improving coordinator queue-empty handling. Added with concrete bash routing pattern.

- `role-identity-trinity` → NEW_SKILL (agents/skills/role-based-agent-identity.md)
  role + goal + backstory as a three-part constraint on agent judgment, not just a label. Backstory calibrates how the agent resolves ambiguous cases. Includes: tools-vs-tasks separation, concrete phase identity pattern for otherness.

**Rejected patterns:**

- `telemetry-collection-design` (CrewAI) — not transferable: specific to Python framework usage tracking; not relevant to otherness's markdown/git-based operation
- `uv-over-pip-install` (CrewAI) — not transferable: Python packaging toolchain choice; otherness has no Python packages
- `crew-control-plane-architecture` (CrewAI AMP) — not transferable: requires a persistent service layer; otherness is stateless by design
- `role-backstory-as-persona` (CrewAI) — partially captured; the persona aspect (flavor text) was excluded; only the judgment-calibration aspect was extracted

---

## 2026-04-14 — langchain-ai/langchain (automated learn session, feat/learn-langchain)

**Files read:**
- `AGENTS.md` (full — global development guidelines, 6,000+ chars)

**Repos assessed:** 1 (langchain-ai/langchain — highest-signal general AI framework with detailed AGENTS.md)

**Patterns extracted:** 3

**Disposition:**

- `ai-disclosure-in-prs` → NEW_SKILL (agents/skills/contribution-hygiene.md §AI Disclosure in Every PR)
  LangChain requires AI contributors to add a disclosure footer to every PR. Directly applicable to otherness — every standalone agent PR should identify itself as AI-generated. Added with exact footer text.

- `commit-scope-enforcement` → NEW_SKILL (agents/skills/contribution-hygiene.md §Commit Scope Is Not Optional)
  LangChain: "All PR titles must include a scope with no exceptions." Otherness already uses conventional commits but doesn't enforce scope strictly. Added concrete check.

- `stable-interface-gate` → EXTENDED_SKILL (agents/skills/reconciling-implementations.md §Stable Interface Gate)
  LangChain: "Always attempt to preserve function signatures for exported/public methods." Maps to otherness's state.json field stability and agent command interface stability. Added as a QA approval gate for PRs that rename/remove public fields.

**Also extracted to contribution-hygiene.md:**
- `pr-description-why-not-what` — describe the why of changes, not what the diff contains
- `remove-dead-code-before-commit` — AI agents often leave commented-out prior approaches

**Rejected patterns:**

- `monorepo-layer-architecture` (LangChain) — not transferable: requires a multi-package Python monorepo; otherness is a single markdown repo
- `model-profiles-cli` (LangChain) — not transferable: specific to LLM model capability tracking; otherness doesn't manage LLM models
- `uv-workspace-management` (LangChain) — not transferable: Python-specific dependency management
- `pr-labeler-config` (LangChain) — partially interesting for otherness label taxonomy, but already solved with gh label commands; deferred

---

## 2026-04-14 — All-Hands-AI/OpenHands (automated learn session, feat/learn-openhands)

**Files read:**
- `AGENTS.md` (full — 7,500+ chars, operational AI software engineer system)

**Repos assessed:** 1 (All-Hands-AI/OpenHands — 71k stars, actively maintained)

**Patterns extracted:** 3 (into one new skill file)

**Disposition:**

- `pr-ephemeral-artifacts` → NEW_SKILL (agents/skills/ephemeral-pr-artifacts.md §The .pr/ Directory)
  `.pr/` directory for reviewer context that auto-cleans on merge. Applicable to otherness CRITICAL tier PRs — adds design.md explaining reasoning without polluting the repo.

- `specific-git-staging` → NEW_SKILL (agents/skills/ephemeral-pr-artifacts.md §Specific Git Staging)
  `git add <file>` not `git add .`. Prevents autonomous agents from accidentally staging state files, temp outputs, or scratch files. Added with audit checklist and the one valid exception (temp state worktree).

- `trigger-based-skill-loading` → NEW_SKILL (agents/skills/ephemeral-pr-artifacts.md §Trigger-Based Skill Loading)
  Load skills only when the current task matches trigger keywords. As otherness skills library grows, loading all files every phase wastes context. Added as an improvement direction with concrete header format.

**Rejected patterns:**

- `lockfile-version-preservation` — not transferable: Python/JS lockfiles; otherness has no dependencies
- `enterprise-directory-pattern` — not transferable: requires separate licensed codebase layer
- `settings-ui-patterns` — not transferable: React frontend; otherness has no UI
- `microagent-frontmatter-format` — partially captured in trigger-based-skill-loading; YAML format is OpenHands-specific

---

## 2026-04-14 — pydantic/pydantic-ai (automated learn session, feat/learn-pydantic-ai)

**Files read:**
- `AGENTS.md` (full — 6,500 chars, exceptionally high-quality agent instructions)

**Repos assessed:** 2 (microsoft/agent-framework — 9k stars, too new; pydantic/pydantic-ai — 16k stars, high-signal AGENTS.md)

**Patterns extracted:** 4 (all into one new skill file)

**Disposition:**

- `responsibility-to-project-not-requester` → NEW_SKILL (agents/skills/agent-responsibility.md §Responsibility Is to the Project)
  "Work for the benefit of the project and all its users, not just the specific user driving you." Completely novel framing — the most important principle in the skill. Directly applicable to otherness agents optimizing for the issue description rather than the broader project health.

- `trust-but-verify-research` → NEW_SKILL (agents/skills/agent-responsibility.md §Trust But Verify)
  Before implementing, research the codebase and related issues independently. Don't just execute the request. Concrete steps: check recent PRs in the same area, search for existing handling, verify scope hasn't shifted.

- `alignment-before-implementation` → NEW_SKILL (agents/skills/agent-responsibility.md §Alignment Before Implementation)
  If scope is unclear: post a comment with two approaches and a stated choice, or open a draft with a PLAN.md. Do NOT post [NEEDS HUMAN] for scope ambiguity — that is for genuine blockers only. Novel distinction from otherness's current [NEEDS HUMAN] escalation pattern.

- `how-matters-as-much-as-what` → NEW_SKILL (agents/skills/agent-responsibility.md §The How Matters)
  "Shipping the best solution is more important than being fast." The instruction files themselves are the product — confusing instructions are bugs. Readability and consistency in standalone.md matter as much as correctness.

**Rejected patterns:**

- `never-add-claude-as-coauthor` (Pydantic AI) — already handled by contribution-hygiene.md AI disclosure pattern; the no-co-author rule is GitHub-platform-specific and doesn't apply to otherness's git-based operations
- `PR-template-ai-checkbox` (Pydantic AI) — requires GitHub PR template infrastructure; not worth adding for otherness's current scale
- `inline-snapshot-testing` (Pydantic AI) — Python-specific testing pattern; not transferable
- `vcrpy-recording-for-api-calls` (Pydantic AI) — Python-specific; not transferable
- `mkdocs-with-mkdocstrings` (Pydantic AI) — documentation toolchain; not transferable to markdown agent files
