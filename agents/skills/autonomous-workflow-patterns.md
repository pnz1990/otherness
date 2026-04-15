# Skill: Autonomous Workflow Patterns

<!-- provenance: coleam00/Archon, README.md, 2026-04-14 -->
<!-- provenance: crewAIInc/crewAI, README.md, 2026-04-14 -->
<!-- otherness-learn: Archon's YAML workflow model; human approval as first-class gate; deterministic vs AI nodes; context refresh in long loops -->
<!-- otherness-learn: CrewAI's autonomy-precision spectrum; Crews vs Flows; conditional routing on state -->

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
- [ ] `gh pr create --title "..." --label "$PR_LABEL"`
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

---

## Autonomy-Precision Spectrum: Choose Per Step <!-- provenance: crewAIInc/crewAI, README.md, 2026-04-14 -->

CrewAI distinguishes two execution modes:

- **Crews** (autonomous): agents collaborate dynamically, delegate to each other, and decide how to solve a problem. Use when the path to the output is genuinely uncertain.
- **Flows** (precise): deterministic event-driven steps with exact state transitions and conditional routing. Use when the execution path must be controlled and reproducible.

The key insight: **both are needed, and the choice is per-step, not per-system.**

```python
# Crews: for uncertain problem-solving (agent decides how)
@listen(fetch_data)
def analyze_with_crew(self, data):
    crew = Crew(agents=[analyst, researcher], tasks=[...])
    return crew.kickoff(inputs=data)

# Flows: for routing on outcome (precise control)
@router(analyze_with_crew)
def route_on_confidence(self):
    if self.state.confidence > 0.8:
        return "high_confidence"
    return "low_confidence"
```

**The otherness implication:** The coordinator (Phase 1) and SM/PM phases are Flows — their behavior must be deterministic given the same state. The engineer (Phase 2) and QA (Phase 3) are Crews — they require genuine agent judgment. When a step in the loop feels "wrong," ask: is this step in the wrong mode? A deterministic step that uses AI judgment will produce inconsistent results. An AI judgment step with hard-coded behavior will fail on novel inputs.

**Concrete check for otherness items:** Before implementing, classify each task step:
- If you can write an exact command that will always produce the correct result → command step (deterministic)
- If the right action depends on reading the specific content → AI step (agent judgment)

Mixing these two types in the same "step" is the source of most agent loop inconsistencies.

---

## Conditional Routing on State, Not Just Success/Failure <!-- provenance: crewAIInc/crewAI, README.md, 2026-04-14 -->

In CrewAI Flows, routing decisions are made on **structured state values**, not just pass/fail:

```python
@router(analyze_with_crew)
def determine_next_steps(self):
    if self.state.confidence > 0.8:
        return "high_confidence"
    elif self.state.confidence > 0.5:
        return "medium_confidence"
    return "low_confidence"
```

This is richer than binary success/failure because it allows the workflow to adapt to the *degree* of success.

**The otherness implication:** The coordinator's item selection already does this implicitly (state=todo vs assigned vs in_review vs done). But the routing logic for "what to do when queue is empty" currently branches only on count=0. Consider: an empty queue due to all items being done is different from an empty queue due to all items being in_review waiting for CI, which is different from all items being needs-human.

**Concrete pattern for otherness coordinator:**
```bash
# Not just "is the queue empty?" — but "why is it empty?"
if   [ $TODO_COUNT   -gt 0 ]; then  # claim next item
elif [ $REVIEW_COUNT -gt 0 ]; then  # wait for CI, check for mergeability
elif [ $BLOCKED_COUNT -gt 0 ]; then # post [STANDALONE] BLOCKED, wait for human
else                                # queue truly empty — generate next batch
fi
```
