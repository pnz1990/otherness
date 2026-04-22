# Skill: Stakeholder Persona Model

<!-- provenance: Priivacy-ai/spec-kitty, architecture/audience/, 2026-04-21 -->
<!-- otherness-learn: spec-kitty has formal audience persona docs with desiderata, frustrations,
     and behavioral cues per stakeholder. Otherness has no structured user model. This skill
     formalises the HiC (project owner) persona and how otherness should orient to them. -->

Load this skill when designing a user-facing feature, writing docs, or deciding what to
surface in health signals. The question "who needs to see this, and what do they need from
it?" is answered by the persona model.

---

## Why personas matter for autonomous systems

An autonomous loop that optimises for internal metrics (CI green, PRs merged, queue velocity)
without a model of who depends on its output will gradually drift from what those people need.
Personas are the corrective — they describe what value actually looks like to the humans the
system serves.

---

## The Project Owner Persona (primary HiC)

**Who they are**: The person who owns the project otherness manages. They have defined the
vision, seeded the initial direction, and now want the system to execute without them needing
to be present.

**Primary goal**: Know that the project is advancing toward the vision without having to check
in more than once per day.

**What they need from otherness:**

| Need | What it means for otherness |
|---|---|
| Signal, not noise | The batch health report must be readable in 30 seconds. Not a log, not a metrics dump — a human sentence. |
| Meaningful progress visible | At least one `✅ Present` item advancing per run. Not CI green. Not chore PRs. Design-doc-backed features. |
| Escalation with enough context | When `[NEEDS HUMAN]` fires, the issue must explain: what happened, what was tried, what the agent cannot decide alone, and what the human needs to provide. Never just "merge failed." |
| Confidence the bar is rising | The vision scan (Step A) should show the pressure lens is finding real gaps, not re-listing items from last week. The bar must demonstrably be harder than it was. |

**What frustrates them:**

- Batch reports they cannot parse without opening the underlying PRs
- Sessions that run and produce only chore/housekeeping PRs with no vision-advancing work
- Escalation issues that don't tell them what to do next
- The same gaps appearing in the vision scan week after week without progress

**Behavioral cues:**

- When the loop is healthy, they check the batch report once a day and move on
- When the loop is amber, they want to understand why in one read — not investigate
- When the loop requires action, they want a clear, specific ask — not an open-ended question

---

## The Platform Team Persona (fleet operator)

**Who they are**: An engineering manager or platform lead who runs otherness across multiple
projects (3–20+). They own the infrastructure, not the individual products.

**Primary goal**: Know at a glance which projects are healthy and which need attention, without
context-switching into individual projects.

**What they need from otherness:**

| Need | What it means for otherness |
|---|---|
| Fleet-level health signal | One view showing all projects: GREEN/AMBER/RED, velocity trend, queue depth, last run. |
| Cost visibility | Which projects are consuming the most tokens? Is total spend within expected range? |
| Anomaly alerting | A project that suddenly uses 5× normal tokens, or has been amber for 3 batches, should alert automatically. |
| Audit trail | For compliance: what did the agent do, when, and why? Not the code — the action log. |

---

## The Evaluator Persona (potential adopter)

**Who they are**: A tech lead or architect who has heard about otherness and is deciding
whether to adopt it for their team. They are skeptical. They have seen AI coding tools overpromise.

**Primary goal**: Determine whether otherness is genuinely autonomous or just a fancier
way to run a session.

**What they need from otherness:**

| Need | What it means for otherness |
|---|---|
| Verifiable claims | Every claim in README.md or docs must be backed by observable evidence (GitHub Actions runs, merged PRs, design doc Present items). |
| Honest limitations | The "Known limitations" section in docs must be accurate and current. A system that hides its gaps is not trustworthy. |
| Fast time-to-value | They should be able to set up a project and see the first autonomous session complete in under 2 hours. Friction here loses them. |
| Governance compatibility | They need to know: can their security team approve this? Does it work within our GitHub Enterprise controls? |

**The test for the evaluator**: Run `/otherness.setup`, wait for one scheduled run, read the
batch report. If they cannot tell from that one read whether the system is working, they will not
adopt it.

---

## Using this skill

When designing a feature or writing a user-facing doc, ask:

1. **Which persona does this serve?** (Project owner, fleet operator, or evaluator)
2. **What do they need from this?** (Use the desiderata table above)
3. **What would frustrate them about a bad version of this?** (Use the frustrations above)
4. **Can they get what they need in one read, without following links?**

If the answer to (4) is no, the design is not done.
