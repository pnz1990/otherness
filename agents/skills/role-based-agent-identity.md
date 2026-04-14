# Skill: Role-Based Agent Identity

<!-- provenance: crewAIInc/crewAI, README.md + docs.crewai.com, 2026-04-14 -->
<!-- otherness-learn: CrewAI's role+goal+backstory trinity; role identity as behavior constraint; description vs identity -->

Load this skill when writing agent instructions (standalone.md, bounded-standalone.md, onboard.md)
or when designing a new agent phase or role.

---

## The Role Identity Trinity <!-- provenance: crewAIInc/crewAI, README.md, 2026-04-14 -->

CrewAI gives each agent three identity fields:

```yaml
researcher:
  role: "{topic} Senior Data Researcher"
  goal: "Uncover cutting-edge developments in {topic}"
  backstory: "You're a seasoned researcher with a knack for finding the most
              relevant information and presenting it clearly."
```

These three fields work together:
- **Role**: what the agent *is* (a noun phrase, not a verb phrase)
- **Goal**: what the agent is trying to achieve (measurable, specific)
- **Backstory**: how the agent's past shapes its judgment (gives it a perspective, not just a task)

The backstory is the surprising one. It is not just flavor text. It calibrates the agent's *judgment* — the decisions it makes when the spec does not specify exactly what to do. An agent with "You're known for finding the most relevant information" will reject tangential findings. An agent with "You excel at comprehensive coverage" will include everything.

**The otherness implication:** otherness's phase headers (`[🎯 COORD]`, `[🔨 ENG]`, `[🔍 QA]`, etc.) are role labels but are missing explicit goals and backstory. When the agent needs to make a judgment call — e.g., "should I open a follow-up issue or fix it in this PR?" — it has no backstory to anchor the decision.

---

## Role Identity as Behavior Constraint, Not Just Label <!-- provenance: crewAIInc/crewAI, README.md, 2026-04-14 -->

The role+goal+backstory trinity is a *constraint* on behavior, not just a description. Two agents with the same task but different identities will make different judgment calls:

| Identity | Same task: "review a PR" | Different outcome |
|---|---|---|
| "Senior QA with zero-tolerance for regressions" | Blocks on any test missing | More rejections |
| "Pragmatic reviewer focused on shipping velocity" | Approves with follow-up items | More approvals |

Neither is wrong — the identity tells the agent *how to weight* the tradeoffs.

**The otherness implication:** The QA phase has a clear identity ("adversarial"), but the coordinator's identity is underspecified. When the coordinator is unsure whether to claim an item or wait, what backstory shapes that judgment? Defining it explicitly would produce more consistent behavior.

**Concrete pattern for otherness:** Each phase in standalone.md could have an explicit identity block at its header:

```
[🔍 QA] — ADVERSARIAL REVIEWER
Role: Adversarial QA engineer
Goal: Find reasons to REJECT. Every merged bug is a failure.
Backstory: You have been burned by rushed merges. You now assume every PR
           has at least one correctness bug until proven otherwise.
```

This is not required today, but if the QA phase is producing inconsistent reviews (sometimes blocking on smells, sometimes not), adding explicit backstory is the lever to tune it.

---

## Roles Do Not Own Tools; Tasks Do <!-- provenance: crewAIInc/crewAI, docs, 2026-04-14 -->

In CrewAI, tools are assigned to agents at the role level, but a task's `expected_output` determines what the agent must actually produce. The role shapes *how* the agent works; the task contract shapes *what* it delivers.

This separation prevents a common failure: an agent with broad tool access and a vague task produces whatever it finds most interesting, not what was asked for.

**The otherness implication:** The spec obligation (declaring-designs skill, Zone 1) is the "expected_output" equivalent. Without it, the engineer produces what seems most interesting. The spec obligation anchors the output, independent of what tools or approaches the agent chooses.

**Concrete check:** Every Phase 2 task must have: (1) a spec with at least one falsifiable obligation, and (2) a concrete success criterion stated in tasks.md before writing code. If these are missing, the engineer will optimize for something other than the spec.
