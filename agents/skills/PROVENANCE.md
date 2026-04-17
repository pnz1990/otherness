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

---

## 2026-04-14 — BerriAI/litellm (automated learn session, feat/learn-aider)

**Files read:**
- `AGENTS.md` (full — 8,000+ chars, LLM gateway with extensive AI agent guidelines)

**Note:** Session targeted Aider-AI/aider first but AGENTS.md was not present (404). Pivoted to BerriAI/litellm (43k stars) which had a high-quality AGENTS.md with strong operational patterns.

**Repos assessed:** 2 (Aider-AI/aider — no AGENTS.md; BerriAI/litellm — 43k stars, high signal)

**Patterns extracted:** 3 (into one new skill file)

**Disposition:**

- `common-pitfalls-section` → NEW_SKILL (agents/skills/explicit-anti-patterns.md §The COMMON PITFALLS Section)
  LiteLLM ends AGENTS.md with a named, numbered list of recurring mistakes. Each has a reason and a concrete fix. Directly applicable to otherness: the 5 most common otherness pitfalls now documented in the skill. The list should be grown as bugs are fixed.

- `config-driven-flags` → NEW_SKILL (agents/skills/explicit-anti-patterns.md §Config-Driven Flags)
  Behavior flags that differ per project (14-day learn threshold, retry counts) should live in otherness-config.yaml, not be hardcoded in standalone.md. Added as an improvement direction — not actionable today, but important for scale.

- `follow-existing-patterns` → NEW_SKILL (agents/skills/explicit-anti-patterns.md §When in Doubt, Follow Existing Patterns)
  Before writing new code, search for how the same thing was done before. Copy exact patterns; don't invent variations. Prevents codebase fragmentation.

**Rejected patterns:**

- `no-type-hints` (Aider CONTRIBUTING.md) — deliberate choice for Python; not transferable to markdown
- `prisma-over-raw-sql` (LiteLLM) — not transferable: database ORM choice; otherness has no database
- `antd-over-tremor` (LiteLLM) — not transferable: React UI library choice; otherness has no frontend
- `vitest-testing-conventions` (LiteLLM) — not transferable: JavaScript test framework
- `litellm-proxy-architecture` (LiteLLM) — not transferable: specific to API gateway design

---

## 2026-04-15 — Two-layer role model: otherness-internal vs. target-project roles (conceptual refinement)

**Source:** Conceptual refinement — recognition that FEE and SysDE roles apply to *target projects*
using otherness, not to otherness building itself. otherness is a markdown/git system with no UI
and no infrastructure to operate. FEE and SysDE are irrelevant to Layer 1 (otherness self-improvement).
They are directly applicable to Layer 2 (projects otherness autonomously develops).

**Patterns extracted:** 3

**Disposition:**

- `two-layer-role-model` → EXTENDED_SKILL (`agents/skills/role-based-agent-identity.md` §Two Layers)
  Added explicit Layer 1 / Layer 2 distinction. Layer 1: the 5 otherness-internal phases (COORD, ENG, QA,
  SDM, PM) which are domain-agnostic. Layer 2: domain-specific role identities for target projects, selected
  by `job_family` in `otherness-config.yaml`. FEE and SysDE live here.

- `job-family-field` → CONFIG (`otherness-config-template.yaml` §project)
  Added `job_family: SDE|FEE|SysDE` field with inline documentation. Defaults to SDE. Controls which
  Layer 2 identity the ENG and QA agents adopt.

- `job-family-runtime-read` → AGENT_LOOP (`agents/standalone.md` Phase 2 + Phase 3)
  Both ENG and QA phases now read `job_family` at runtime from `otherness-config.yaml` and adopt the
  matching Layer 2 identity. Graceful default to SDE if field absent — fully backward compatible.

**Rejected patterns:** none — this was a conceptual refinement, not a source study.

---

## 2026-04-15 — Amazon Role Guidelines (manual import) + AI-Assisted Coding survey docs

**Files read:**
- `sde-role-guidelines.md` — L4/L5/L6/L7 SDE expectations (Amazon official, Nov 2024)
- `fee-role-guidelines.md` — L5/L6 FEE expectations (Amazon official, Oct 2022)
- `pm-role-guidelines.md` — L5/L6/L7 PM expectations (Amazon official, May 2019)
- `sdm-role-guidelines.md` — L5/L6/L7/L8 SDM expectations (Amazon official, Apr 2025)
- `sysde-role-guidelines.md` — L4/L5/L6/L7 SysDE expectations (Amazon official, Jun 2025)
- `uxr-role-guidelines.md` — L4/L5/L6/L7 UXR expectations (Amazon official, Oct 2023)
- EKS Lighthouse AI-Assisted Coding survey doc (internal, 2026)
- EKS Lighthouse AIM Package design doc (internal, 2026)

**Patterns extracted:** 5

**Disposition:**

- `role-definitions-for-phases` → EXTENDED_SKILL (`agents/skills/role-based-agent-identity.md`)
  Added full role+goal+backstory definitions for all 5 otherness phases (COORD, ENG, QA, SDM, PM)
  sourced from Amazon's official role guidelines. L5 SDE = ENG, L6 SDE = QA, L6 SDM = SDM phase,
  PM III = PM phase. The key contribution: backstory blocks calibrate agent judgment for each phase's
  specific tradeoffs (correctness over velocity for QA, simplification over building for PM, etc.)
  Wired into standalone.md phase headers.

- `judgment-vs-execution-axis` → EXTENDED_SKILL (`agents/skills/role-based-agent-identity.md` §Task Classification)
  From the SDE role guidelines: work divides into judgment-heavy (architecture, ambiguous scope) and
  execution-heavy (well-specified, deterministic). Maps to HIHO/LILO task framework from the survey doc.
  Added as queue item tagging guidance for Phase 1b.

- `sdm-operational-checks` → EXTENDED_SKILL (standalone.md Phase 4)
  From SDM L6 + SysDE role guidelines: the SM phase becomes SDM with explicit operational checks —
  stale needs-human issues, orphaned worktrees, state branch verification, repeated-error pattern detection.
  SM renamed to SDM throughout.

- `uxr-lens-for-pm` → EXTENDED_SKILL (`agents/skills/role-based-agent-identity.md` §PM)
  UXR role adds a specific question to the PM phase: "where does the product violate the user's mental
  model?" For otherness: every [NEEDS HUMAN] is a data point about where the agent's world model
  diverged from reality. PM phase now includes a UXR lens check.

- `implicit-context-explicit-tools` → NOTE (future skill candidate)
  From the AIM Package design doc: context packages should be mostly implicit (patterns the agent infers)
  while tools/commands should be explicit (exact commands in SOPs). Applies to otherness's skills files:
  skills should express patterns and judgment calibration; standalone.md should express exact commands.
  The current skills files already follow this structure. Filed for awareness, no immediate change.

**Rejected patterns:**

- `aim-package-microservices` — not transferable: AIM CLI-specific architecture; otherness uses git + markdown
- `kiro-spec-workflows` — already captured in declaring-designs.md skill
- `sync-steering.sh` — Amazon-internal toolchain; not transferable
- `fee-specific-dimensions` (accessibility, i18n, real user metrics) — frontend-specific; otherness has no UI
- `sysde-sla-ORR-patterns` — operational readiness reviews for deployed services; otherness is not a deployed service
- `sdm-people-management` (hiring, promotion, performance reviews) — human team management; not applicable
- `uxr-research-methodology` (HCI, ethnography, user studies) — research methods for human participants; not applicable
- `"architects not babysitters" framing` — good positioning language, already captured in vision.md rewrite

---

## 2026-04-14 — microsoft/autogen (automated learn session, feat/learn-autogen)

**Files read:**
- `CONTRIBUTING.md` (full — triage process, versioning, docstring standards)

**Note:** AGENTS.md not present (404). CONTRIBUTING.md had high-quality triage and process patterns.

**Repos assessed:** 1 (microsoft/autogen — 57k stars, multi-agent orchestration framework)

**Patterns extracted:** 3 (into one new skill file)

**Disposition:**

- `triage-with-explicit-categories` → NEW_SKILL (agents/skills/triage-discipline.md §Triage Has Explicit Per-Category Responsibilities)
  AutoGen runs formal weekly triage with per-category checklists: issues, PRs, discussions, security. The SM phase should be equally structured. Added bash queue commands for each category.

- `awaiting-response-label-lifecycle` → NEW_SKILL (agents/skills/triage-discipline.md §Awaiting Response Tagging)
  needs-human labels should be removed when the blocker is resolved (human replied). The SM should check and clear stale needs-human labels each batch.

- `breaking-change-versioning` → NEW_SKILL (agents/skills/triage-discipline.md §Breaking Change Detection)
  Standalone.md changes to state.json schema or phase structure are breaking changes. Improvement direction: CHANGELOG.md for agent interface changes. Appropriate for scale >10 projects.

**Rejected patterns:**

- `contributor-license-agreement` (AutoGen) — legal process; not applicable to autonomous agent
- `versionadded-sphinx-annotations` (AutoGen) — Python Sphinx docs; not transferable to markdown
- `codespace-based-pr-review` (AutoGen) — GitHub Codespaces specific; not a core pattern

---

## 2026-04-15 — pnz1990/kardinal-promoter (live session extraction)

**Source type:** Live architecture review session (not a `/otherness.learn` run — extracted manually)

**What was studied:**
- A thorough architectural review of kardinal-promoter against krocodile 745998f
- 11 distinct findings produced across four categories: documentation drift, unused primitives, structural redundancy, missing reactivity
- The review methodology used was adversarial and source-verified (every claim checked against code)

**Files that informed the extraction:**
- `AGENTS.md` — false claims found: NewCELEnvironment, schedule.* as Graph functions
- `docs/design/10-graph-first-architecture.md` — Q3 claim false
- `docs/design/11-graph-purity-tech-debt.md` — status claims vs actual code
- `pkg/reconciler/policygate/reconciler.go` — actual schedule.* implementation
- `pkg/reconciler/policygate/cel_evaluator.go` — actual CEL environment construction
- `pkg/graph/builder.go` — baked-in literals vs live CEL references
- `pkg/reconciler/bundle/reconciler.go:SetupWithManager` — missing Pipeline watch
- `/tmp/kro-review/experimental/docs/design/001-graph.md` — krocodile primitives (Definition, forEach, WatchKind, Decorator)
- `/tmp/kro-review/experimental/docs/design/005-standard-library.md` — Decorator/Kind/Singleton

**Patterns extracted:** 2

**Disposition:**

- `architectural-audit` → NEW_SKILL (`agents/skills/architectural-audit.md`)
  The methodology used in this session — adversarial claim verification, four audit lenses,
  structured output format (issues + doc PR, no code changes) — is fully generalizable to any
  project. Captures: the four lenses (drift, unused primitive, structural redundancy, missing
  reactivity), the adversarial stance, scope declaration, common false positives, output artifacts.
  Also created `agents/arch-audit.md` (the agent that loads this skill) and
  `.opencode/command/arch-audit.md` (the thin project-level launcher).

- `live-session-to-skill-extraction` → EXTEND_SKILL (this PROVENANCE.md entry)
  Pattern: a live work session that produces high-quality systematic findings is a valid
  source for `/otherness.learn`-style skill extraction, even without running the learn command.
  The adversarial review methodology was derived organically from the session and then
  distilled post-hoc into a reusable skill. This is a valid and encouraged workflow.

**Rejected patterns:**

- `krocodile-specific-upgrade-protocol` — too domain-specific (Kubernetes/krocodile)
- `kardinal-cel-context-map-pattern` — project-specific implementation detail, not transferable
- `prstatus-crd-pattern` — Kubernetes CRD design pattern, not an agent process pattern
- `minor-version-for-breaking-changes` (AutoGen) — semver versioning; otherness doesn't version releases yet (deferred to Option B)

---

## 2026-04-17 — pnz1990/otherness (session sess-518cc5ec, live session extraction)

**Session type**: live implementation session (batches 11-21 of autonomous loop)

**What was implemented:**

20+ improvements across the otherness codebase. Key patterns extracted:

**Patterns extracted:** 6

**Disposition:**

- `design-doc-driven-queue-generation` → EXTEND_SKILL (existing declaring-designs.md)
  When a COORD phase reads `docs/design/` files for `## Future (🔲)` items, it generates
  a queue that is grounded in declared design intent rather than just roadmap deliverables.
  The queue grows organically as design docs are written. Machine-readable markers
  (`## Future (🔲)` / `## Present (✅)`) create a bidirectional feedback loop between
  design state and work queue. The COORD regex `r'^## Future'` is the gate.

- `critical-tier-self-review-discipline` → EXTEND_SKILL (existing agent-responsibility.md)
  CRITICAL tier changes (phases/*.md, standalone.md) require an adversarial 5-check self-review
  before autonomous merge. Three out of six CRITICAL PRs in this session found WRONG findings
  on first pass that were corrected before merge. The self-review is genuinely adversarial —
  the agent must assume there is a bug and look for counter-evidence. Rate: 50% bug-find rate
  on CRITICAL tier PRs. Without this protocol, half the CRITICAL changes would have shipped buggy.

- `heredoc-__file__-failure-mode` → EXTEND_SKILL (existing explicit-anti-patterns.md)
  Python `__file__` is undefined inside bash heredocs. Scripts that use
  `os.path.abspath(__file__)` to find their own path fail silently when embedded in heredocs.
  Fix: pass the path as an environment variable from the shell (`SCRIPT_DIR="$SCRIPT_DIR" python3 - <<'EOF'`
  ... `config_path = os.environ.get('SCRIPT_DIR', '.')`). This pattern appeared in test.sh
  and was silently skipping the integration check for all previous sessions.

- `is-done-filter-precision` → EXTEND_SKILL (existing agent-coding-discipline.md)
  Substring matching (`key in merged_pr_blob`) causes false positives when the key appears
  in unrelated PR titles. Fix: iterate per PR title, check if the first 60 chars of the
  item description appear in an individual title. This prevented valid queue items from
  being silently filtered. The per-title iteration is the correct pattern for intent matching.

- `design-doc-trigger-guard` → EXTEND_SKILL (existing declaring-designs.md)
  Design docs with future items that are gated on external triggers (human decision, quota)
  should use a section header that does NOT match the COORD regex. Renaming `## Future (🔲)`
  to `## Planned (🔲 — trigger required)` prevents premature queue item generation.
  The COORD queue generator reads `^## Future` — any other heading is invisible to it.

- `ai-step-graceful-fallback` → EXTEND_SKILL (existing autonomous-workflow-patterns.md)
  Every AI-STEP in a phase file must have a graceful fallback path (no-op) when the required
  resources are unavailable (empty project list, missing files, gh API failure). A block that
  can crash or produce wrong output when called on any of the ~100 projects in the fleet is
  a global deployment risk. Audit each new AI-STEP: what happens when each input is empty or
  missing? Only add the step if all paths are graceful.

**Rejected patterns:**

- `otherness-specific-batch-sequence` — the specific batch numbering and PR numbers are
  project-specific context, not transferable patterns.
- `alibi-journey-2-failure` — specific operational failure requiring human restart.
  Not a generalizable skill; documented in DoD Journey Status instead.
