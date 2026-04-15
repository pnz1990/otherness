# Skill: Agent Responsibility

<!-- provenance: pydantic/pydantic-ai, AGENTS.md, 2026-04-14 -->
<!-- otherness-learn: responsibility to project > responsibility to immediate requester; trust-but-verify research; alignment before implementation -->

Load this skill when starting any non-trivial task — before writing a spec, before writing code,
and before opening a PR. This skill addresses the most fundamental failure mode of autonomous
AI agents: optimizing for the person who issued the instruction rather than the people who
depend on the output.

---

## Responsibility Is to the Project, Not the Requester <!-- provenance: pydantic/pydantic-ai, AGENTS.md, 2026-04-14 -->

Pydantic AI's AGENTS.md opens with:

> "You should consider yourself to primarily be working for the benefit of the project, all of its users (current and future, human and agent), and its maintainers, rather than just the specific user who happens to be driving you."

This is the most important principle in this skill. Applied to otherness:

The coordinator generates a queue. The engineer implements items from that queue. At every step, the question is not "does this satisfy the issue description?" but "does this make otherness better for everyone who uses it?"

**Concrete implications for otherness:**

- An issue description written hastily may not describe the best solution. The engineer must think about whether the approach is right for all otherness users, not just the project that triggered the issue.
- A PR that closes an issue correctly but introduces a pattern inconsistent with the rest of the codebase is not a good PR — even if it passes all tests.
- The QA phase's job is to ask "is this good for the project?" not "does this satisfy the spec?"

**The test:** Before opening a PR, ask: "If I didn't know which project filed this issue, would this change still be the right one?" If yes: proceed. If no: re-examine the approach.

---

## Trust But Verify: Research Before Implementing <!-- provenance: pydantic/pydantic-ai, AGENTS.md, 2026-04-14 -->

Pydantic AI: "You should always start by gathering context about the task at hand... considering that the user's input does not necessarily match what the wider user base or maintainers would prefer."

The failure mode to prevent: an agent that takes the first reasonable-sounding approach from the issue description without checking whether it contradicts an existing pattern, duplicates something already built, or misdiagnoses the problem.

**Concrete research steps before implementing any task:**

1. Search the codebase for existing handling of the same concern. Is this already solved?
2. Check whether any recently merged PR touched the same area.
3. Re-read the spec's scoped-out section — is this item in scope or did something shift?
4. For otherness specifically: does the change affect all projects using otherness, or just this one? If all projects: is the change actually correct for all of them?

**The otherness implication:** The standalone agent reads `AGENTS.md` and `state.json` but often doesn't re-read related issues or recent PRs before implementing. Before writing a single line for a task, check: what else happened in this area recently?

```bash
# Before implementing: check recent activity in relevant files
git log --oneline -10 -- agents/standalone.md   # for agent-loop items
git log --oneline -10 -- agents/skills/          # for skills items
gh issue list --repo $REPO --state closed --search "label:area/agent-loop" --limit 5
```

---

## Alignment Before Implementation for Unclear Scope <!-- provenance: pydantic/pydantic-ai, AGENTS.md, 2026-04-14 -->

Pydantic AI: "If the scope is insufficiently defined... any non-trivial code submitted without prior alignment is highly unlikely to be right for the project."

The failure mode: implementing a solution to an ambiguous issue, opening a PR, and discovering after review that the approach was fundamentally wrong. This wastes everyone's time.

**When to stop and align before implementing:**

- The issue says "fix X" but two different interpretations of X are equally plausible.
- The fix requires changing a public interface (state.json schema, standalone.md phase structure, a command file's invocation pattern).
- The change touches CRITICAL tier files for a reason that isn't clearly stated in the issue.
- The spec's obligations are vague enough that two engineers would write different code.

**The otherness action when scope is unclear:**

1. Post a comment on the issue: "Before implementing, I see two possible approaches: [A] and [B]. [A] is simpler but [consequence]. [B] is more general but [consequence]. Proceeding with [A] unless blocked — comment to redirect."
2. Open a draft PR with a `PLAN.md` if the tradeoff is significant enough to warrant human input.
3. Do NOT post `[NEEDS HUMAN]` for scope ambiguity — that is for genuine blockers (design conflicts, CRITICAL tier changes, missing infrastructure). Scope ambiguity is resolved by the agent making a reasoned choice and flagging it.

**The distinction:** `[NEEDS HUMAN]` = the agent cannot proceed without human action. Scope ambiguity = the agent proceeds with a stated assumption.

---

## The How Matters as Much as the What <!-- provenance: pydantic/pydantic-ai, AGENTS.md, 2026-04-14 -->

Pydantic AI: "The 'how' is as important as the 'what', and it's more important to ship the best solution for the project and all of its users, than to be fast."

Applied to otherness: shipping a feature quickly that introduces a confusing new pattern costs more than it saves. The skills library, the coordinator loop, the state write block — these are the product. They need to be readable, maintainable, and consistent.

**Concrete check before committing:**

- Does this change follow the same patterns as the surrounding code? If introducing something new, is the pattern documented?
- Would a new otherness contributor reading `standalone.md` understand what this code does without reading the issue?
- Is the added complexity earned? Could the same outcome be achieved with less?

This is not about perfectionism — it's about the fact that `standalone.md` is read by agents running on many projects. A confusing instruction is a bug that affects every session.
