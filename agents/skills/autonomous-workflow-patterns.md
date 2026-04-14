# Skill: Autonomous Workflow Patterns

<!-- provenance: coleam00/Archon, README.md, 2026-04-14 -->
<!-- otherness-learn: Archon's YAML workflow model; human approval as first-class gate; deterministic vs AI nodes; context refresh in long loops -->

Load this skill when designing or reviewing how a feature is implemented across multiple steps.

These patterns come from Archon — a YAML-defined workflow engine for AI coding agents.
The patterns are transferable to otherness even though otherness uses markdown instruction loops.

---

## Human Approval Is a Named Gate, Not an Emergency Stop <!-- provenance: coleam00/Archon, README.md, 2026-04-14 -->

In Archon, human approval is a first-class workflow node:
```yaml
- id: approve
  depends_on: [review]
  loop:
    prompt: "Present changes for review. Address feedback."
    until: APPROVED
    interactive: true   # pauses and waits for human input
```

In otherness, the equivalent is `[NEEDS HUMAN]`. But there is a difference:
- `[NEEDS HUMAN]` is an escape hatch — something unexpected happened.
- A named approval gate is **planned** — it is a deliberate stopping point designed into the workflow.

**The otherness implication:** When an item's spec includes a step that requires human judgment by design (not because the agent is stuck), the spec should say so explicitly. The task item should include a step like "Open draft PR and wait for human review before merging." This is not an escalation — it is the correct behavior.

Example spec wording:
```
Obligations:
- Implement X
- Open a draft PR with a description explaining the approach
- Post [NEEDS HUMAN: approve-before-merge] in the PR body and issue comment
- Do not merge — wait for human approval
```

The difference from an emergency `[NEEDS HUMAN]`: the agent completes all its work, opens the PR, then explicitly stops and requests approval. It is not blocked; it is waiting correctly.

---

## Deterministic Steps Do Not Need AI <!-- provenance: coleam00/Archon, README.md, 2026-04-14 -->

Archon distinguishes AI nodes from bash nodes:
```yaml
- id: run-tests
  bash: "bun run validate"   # deterministic — no AI involved
```

The principle: AI judgment adds value at steps with genuine uncertainty (planning, code generation, review). Steps with deterministic outputs (run tests, push branch, create PR, update state.json) should be exact commands, not AI-generated actions.

**The otherness implication:** In the engineer phase, steps like "push the branch," "create the PR," and "run the build" should be specified as exact shell commands in the spec's tasks.md, not as open-ended AI decisions. The agent should not reason about how to push a branch — it should run the exact command.

When writing tasks.md, distinguish AI steps from command steps:
```markdown
# Tasks

## AI steps (require judgment)
- [ ] Read the design doc and identify which files need to change
- [ ] Implement the clue evaluator for `isBeside` type
- [ ] Write a failing unit test for the edge case where...

## Command steps (deterministic, run exactly)
- [ ] `npm test` — must exit 0
- [ ] `git push origin feat/<item-id>`
- [ ] `gh pr create --title "..." --label "alibi"`
```

This prevents the agent from burning context on steps where there is nothing to reason about.

---

## Context Refresh in Long Loops <!-- provenance: coleam00/Archon, README.md, 2026-04-14 -->

Archon supports `fresh_context: true` per loop iteration — each iteration gets a clean session rather than accumulating all prior context.

The problem this solves: in a long autonomous loop (many items, many tool calls), the agent's context fills with the history of previous items. The model begins to reason about old state that is no longer relevant, occasionally confusing past decisions with current ones.

**The otherness implication:** The standalone agent already re-reads `AGENTS.md` and `state.json` at the start of each item. This is the correct pattern. However, within a long multi-step implementation (many files, many test runs), the agent should periodically re-read the spec rather than relying on accumulated context.

Guideline: if implementing an item requires more than ~8 distinct file operations, re-read the spec.md and tasks.md before continuing. State what has been done and what remains before proceeding. This is a checkpoint, not a restart.

---

## Single Registry for Extension Points <!-- provenance: NousResearch/hermes-agent, AGENTS.md, 2026-04-14 -->

Hermes defines all slash commands in a single `COMMAND_REGISTRY`. Every downstream consumer — CLI dispatch, gateway dispatch, Telegram menu, Slack routing, autocomplete, help text — derives from that registry automatically. Adding a command requires editing one file.

The anti-pattern it prevents: dispatch logic scattered across multiple files, where adding a feature requires touching the CLI handler, the gateway handler, the help text, and the menu separately. This is a correctness risk (miss one and the feature is broken in one context) and a maintenance burden.

**The otherness implication:** Any time a project defines a set of named entities that need consistent behavior across multiple contexts (routes, commands, event handlers, tool types, clue types), define them in one registry. Every downstream consumer reads from the registry.

Applied to the ALIBI project: the 14 clue type evaluators are defined as a registry in `src/engine/clues.ts`. The generator, the solver, the QA checklist, and the Playwright test suite all reference the same type names. If a new clue type is added, it is added to the registry once, and all consumers automatically handle it.

This is not just an architecture tip — it is a correctness property: an entity that exists in the registry but not in all consumers is a bug.
