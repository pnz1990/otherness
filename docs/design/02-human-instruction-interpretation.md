# 02: Human instruction interpretation — declarative translation

> Status: Active | Created: 2026-04-17

---

## What this does

When a human issues an instruction during a session — in the conversation, in an issue,
or in the config — the agent does not execute it literally. It translates the intent
into a declarative artifact (a vision update, a design doc entry, or a roadmap item)
and then works from that artifact. The human sees what was understood before anything
is built.

This is the D4 model applied to human communication. Imperative instructions are
input signals, not execution commands.

---

## Present (✅)

- ✅ D4 classification at session start — IMPERATIVE/DECLARATIVE/INFRA classification before acting (PR #145, 2026-04-17)
- ✅ Translation format posted before implementation — `[📋 D4 TRANSLATION]` block with Heard/Intent/D4 layer/Artifact (PR #145, 2026-04-17)
- ✅ 60s wait before acting on translation — human can correct before agent proceeds (PR #145, 2026-04-17)
- ✅ Infra exception — pure maintenance tasks skip translation, go directly to spec (PR #145, 2026-04-17)
- ✅ Translation artifact persisted in spec — D4 translation saved to `.specify/d4/translation.md` before proceeding (PR #154, 2026-04-17)
- ✅ GitHub issue instructions intercepted — coord.md checks last 5 comments on claimed issue for imperative instructions, posts D4 translation (PR #167, 2026-04-17)

## Speculative (🔲 — not a queue input, deferred until needed)

> ⚠️ Items in this section are explicitly deferred as speculative. COORD does NOT generate queue items from this section.

- 🔲 Translation confidence score — agent rates its own translation confidence; low confidence triggers the clarifying question even for non-ambiguous instructions (deferred: speculative, may increase friction)

---

## Zone 1 — Obligations

**O1 — Classify before acting.**
When a human instruction arrives, the agent first classifies it:
- **Declarative** — already expressed as a design intent, vision update, or roadmap item. Proceed.
- **Imperative** — expressed as a direct action ("add X", "fix Y", "update Z"). Translate first.
- **Ambiguous** — could be either. Ask one question to disambiguate, then translate.

**O2 — Translate imperative instructions to declarative artifacts.**
For imperative instructions, the agent proposes what the equivalent declarative artifact
would be — which layer of the D4 hierarchy it belongs to and what it would say. It posts
this translation before doing any implementation work.

Translation output format:
```
[📋 D4 TRANSLATION]
Heard:     "<the instruction verbatim>"
Intent:    <one sentence — what the human actually wants, not what they said>
D4 layer:  <vision / roadmap / design doc / spec>
Artifact:  <what would be written — a vision update, a 🔲 Future item, a roadmap stage, etc.>
Question:  <one question if anything is ambiguous — otherwise omit>
Proceeding in 60s unless you correct the translation.
```

**O3 — Act on the translation, not the original instruction.**
After posting the translation, the agent proceeds using the D4 hierarchy. It creates or
updates the design doc `🔲 Future` item, writes the spec referencing that design doc,
then implements. The original imperative instruction is not the work order — the design
artifact is.

**O4 — Surface scope creep and missing design docs.**
If an imperative instruction implies work that has no corresponding design doc, the agent
creates the design doc first (per eng.md §2b O1). If the instruction implies work outside
the current roadmap stage, it says so before proceeding.

**O5 — Never silently interpret.**
The agent never silently infers what the human meant and acts on that inference. The
translation is always posted. Silent inference is how design intent diverges from
implementation.

**O6 — Infra and ops exceptions.**
Pure maintenance tasks with no user-visible behavior change (fix a broken test, clean up
a stale branch, update a dependency version) do not require translation. These are
classified as infra-only and proceed directly to spec with `## Design reference: N/A`.

---

## Zone 2 — Implementer's judgment

- How long to wait before acting on the translation: 60 seconds is the default. For
  urgent ops tasks (CI is red, broken deploy) the agent may act immediately and note
  the exception.
- Whether to ask a clarifying question: only if the translation would be materially
  different depending on the answer. One question maximum. Do not interrogate.
- How verbose the translation output is: keep it short. The intent line is the most
  important. Everything else is confirmation.

---

## Zone 3 — Scoped out

- Intercepting instructions that arrive via GitHub issues (those go through the normal
  queue; this applies to direct conversation messages)
- Refusing to act on instructions that are out of scope (the agent translates and flags,
  but does not refuse)
- Natural language parsing of complex multi-part instructions (treat them as one intent,
  ask if genuinely ambiguous)

---

## Examples

**Imperative → declarative translation:**

```
Human:  "add a --verbose flag to the CLI"

[📋 D4 TRANSLATION]
Heard:     "add a --verbose flag to the CLI"
Intent:    Improve CLI debuggability by exposing internal state on request
D4 layer:  design doc → spec
Artifact:  In docs/design/03-cli.md §Present/Future:
           🔲 --verbose flag: emit controller events and reconciler decisions
           to stderr when set. Useful for debugging stuck promotions.
Proceeding in 60s unless you correct the translation.
```

**Imperative that implies a missing design doc:**

```
Human:  "make the dashboard show blocked pipelines first"

[📋 D4 TRANSLATION]
Heard:     "make the dashboard show blocked pipelines first"
Intent:    Prioritize operator attention by surfacing actionable items at the top
D4 layer:  design doc (new section)
Artifact:  docs/design/06-kardinal-ui.md currently has no section on sort order.
           Will add to Future (🔲):
           🔲 Pipeline list default sort: blocked (needs_human > 0 or ci_red) first,
              then by blockage_duration desc.
           Then spec → implement.
Proceeding in 60s unless you correct the translation.
```

**Ambiguous instruction:**

```
Human:  "we need better error messages"

[📋 D4 TRANSLATION]
Heard:     "we need better error messages"
Intent:    Unclear — could mean CLI error output, UI error states, or controller logs
Question:  Which surface? CLI commands, the web UI, or controller/reconciler logs?
```

**Pure infra — no translation needed:**

```
Human:  "the lint step is broken, fix it"
→ Classified as infra-only. Proceeding directly to fix.
```
