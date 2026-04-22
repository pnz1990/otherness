# Skill: Governed Consultation Patterns

<!-- provenance: Priivacy-ai/spec-kitty, AGENTS.md + architecture/2.x, 2026-04-21 -->
<!-- otherness-learn: spec-kitty has three distinct operator surfaces (do/advise/ask) each with
     different authority levels and a durable invocation record. Otherness has /otherness.vibe-vision
     and /otherness.run but no consultation surface with audit trail. This skill defines when to use
     each consultation mode and what must be recorded. -->

Load this skill when a human-facing command (vibe-vision, run, status, arch-audit) starts a session.
The consultation pattern determines what authority the agent has and what must be logged.

---

## Three consultation modes

Spec-kitty distinguishes `do`, `advise`, and `ask`. The principle transfers directly:

| Mode | Authority | When to use | What must be recorded |
|---|---|---|---|
| **Execute** | Agent acts autonomously within its mandate | Scheduled sessions, `/otherness.run` | Session ID, items claimed, PRs merged, health signal |
| **Advise** | Agent proposes; human decides | `/otherness.vibe-vision`, `/otherness.arch-audit` | Session ID, gaps identified, design doc items written, human's response (if any) |
| **Ask** | Agent needs information before proceeding | `[NEEDS HUMAN]` escalation | Issue number, question asked, what was blocked, what the human must provide |

---

## The invocation record principle

**Every consultation must produce a record that answers: who was consulted, about what, and what was concluded.**

spec-kitty opens an invocation record when `advise` or `do` starts, and closes it when the
session ends. The record is queryable after the fact.

For otherness, the equivalent is:

- **Execute sessions**: SM health comment closes the record. Every session that runs must produce
  a health comment. A session that ends without one has an incomplete invocation record — this is
  a bug, not a normal outcome.

- **Vibe-vision sessions**: The session must post to the report issue on start AND on completion.
  Start: "Vision scan started: studying X areas." Completion: "Vision scan complete: N gaps found,
  M new design doc items written." Without these two posts, the session has no audit trail.

- **[NEEDS HUMAN] escalations**: The issue IS the invocation record. It must be complete enough
  for the human to act without additional context. Minimum fields: what happened, what was tried,
  what the agent cannot decide, what the human must provide.

---

## Authority boundaries are not vague

The authority granted to each mode must be explicit and non-overlapping:

- An **advise** session (vibe-vision) must not merge PRs. It writes to docs only.
- An **execute** session (run) must not change the vision or roadmap direction. It implements only.
- An **ask** escalation must not take any action while waiting. It pauses.

Crossing these boundaries is the agent overreaching. The human must be able to trust that a
vibe-vision session cannot merge code, and a run session cannot change the vision.

---

## The "mostly invisible, highly visible outcomes" principle

<!-- provenance: Priivacy-ai/spec-kitty, glossary/contexts/practices-principles.md, 2026-04-21 -->

spec-kitty's practices-principles glossary states two complementary requirements:
- Governance checks should run by default with **minimal interruption** during normal flow.
- Conflict results, block reasons, and clarification decisions must be **visible in artifacts/logs**.

Applied to otherness:

**Mostly invisible**: The CI gate, the board status update, the spec quality check — these should
run without any human-visible output when they pass. Don't log "CI gate: all checks passed" on
every PR. Only log when something requires attention.

**Highly visible outcomes**: When a merge is blocked, when a spec fails the quality gate, when
a session produces zero vision-backed PRs — these must be prominent, not buried. The AMBER health
signal, the `[NEEDS HUMAN]` issue, the `[COST ANOMALY]` notice — these should stand out clearly
in the report issue.

**The test**: Is the human's attention being drawn to things that require it, and only to those
things? A system that cries wolf (logs everything) and a system that goes silent (logs nothing)
both fail this test. The right calibration: green batches are invisible; anything non-green
is explicitly flagged.
