# 05: Vibe-Vision — Conversational Vision Authoring

> Status: Active | Created: 2026-04-17
> Applies to: all projects managed by otherness

---

## What this does

A human runs `/otherness.vibe-vision` and enters a conversation with the agent.
They talk about what the product should become. The agent listens, asks clarifying
questions, reflects back what it heard, and — when the human says it's right —
writes the validated intent as D4 artifacts: vision updates, roadmap additions,
design doc stubs, user-facing documentation.

The autonomous team (other sessions running `/otherness.run` in a loop) picks those
artifacts up and executes them. The human never needs to talk to the execution team
directly. They talk to the vision agent. The vision agent talks to the docs. The docs
talk to the agents. The agents build the product.

This is how intent flows into software without the human being in the implementation
loop at all.

---

## The gap this fills

Today, a human who wants something new has two options:
1. Open a GitHub issue — too low-level. Forces them to think in tasks, not outcomes.
2. Edit `docs/aide/vision.md` directly — too raw. No dialogue, no reflection, no
   structured translation into the downstream D4 layers.

Both options require the human to already know the D4 hierarchy and write in it.
Vibe-vision inverts this: the human speaks naturally, and the agent does the
translation, structuring, and artifact writing.

---

## Present (✅)

*(Not yet implemented — this is the design doc for a new capability.)*

## Future (🔲)

- 🔲 `/otherness.vibe-vision` command — interactive vision authoring session
- 🔲 Structured dialogue protocol — listen, reflect, validate loop before writing
- 🔲 Artifact cascade — validated dialogue output flows into vision.md → roadmap.md
  → docs/design/ stubs → docs/<feature>.md user docs, in that order
- 🔲 Human validation gate — agent proposes each artifact, human confirms before it
  lands on main (PR or direct push with human approval comment)
- 🔲 `otherness.run` pickup — design doc stubs from vibe-vision contain Future items
  that COORD immediately reads as queue inputs on next startup

---

## Zone 1 — Obligations

**O1 — Vibe-vision operates only at the vision layer.**
The agent does not write specs, implementation plans, or code during a vibe-vision
session. It writes: `docs/aide/vision.md` updates, `docs/aide/roadmap.md` entries,
`docs/design/<N>-<area>.md` stubs, `docs/<feature>.md` user-facing docs. Everything
below that layer is left to the autonomous execution team.

**O2 — Dialogue before artifacts.**
The agent must reflect back what it heard before writing anything. The human must
confirm (or correct) the reflection. No artifact is written from a single exchange —
the loop is: human says X → agent reflects Y → human confirms or corrects → artifact.

**O3 — Every artifact is a valid D4 document.**
Artifacts written during vibe-vision must conform to the same structure as
hand-written D4 documents. Design doc stubs must have the standard structure (What
this does / Present / Future / Zone 1 / Zone 2 / Zone 3). Vision updates must
maintain vision.md's voice and format. The agent is not writing a summary or notes —
it is writing the actual document that will govern future work.

**O4 — Artifacts land on main through a visible gate.**
The agent proposes all artifacts before writing them. The human reviews and confirms.
The gate comment is: "Say 'ship it' to commit. Say 'change X' to adjust." Nothing
lands on main until the human explicitly approves.

**O5 — Design doc stubs contain machine-readable Future items.**
Every `docs/design/` stub created by vibe-vision must contain at least one `🔲 Future`
item in the correct format so COORD can generate queue items from it immediately.
A stub with no Future items is invisible to the execution team.

**O6 — User docs are first-class output.**
For any capability the human describes that involves user-facing behavior, the agent
creates a `docs/<feature>.md` customer doc stub alongside the design doc. This is the
human-readable description of what the feature does from the user's perspective.
It marks unimplemented sections `🔲 Future`.

---

## Zone 2 — Implementer's judgment

- How many dialogue turns before writing artifacts: at least two (reflect + confirm),
  but the agent judges when the human's intent is stable enough to artifact.
- Whether to open a PR or push directly: PR is safer (explicit human review gate).
  Direct push with a confirmation comment is acceptable if the human said "ship it"
  or equivalent in the dialogue.
- How to handle an instruction that spans multiple feature areas: create one design
  doc stub per area. Do not collapse unrelated areas into one doc.
- Whether to update vision.md or just create design docs: update vision.md only if
  the dialogue surfaced something that changes the product's core identity or direction.
  New features that fit within the existing vision → design docs only.
- How long the session runs: until the human says "done", "ship it", or leaves. The
  agent does not end the session — the human does.

---

## Zone 3 — Scoped out

- Vibe-vision does not read existing code to understand what's already built. It reads
  `docs/aide/` and `docs/design/` — the D4 layer is the source of truth, not the code.
- Vibe-vision does not interact with GitHub issues or the work queue directly. It writes
  design docs. COORD reads design docs. The separation is intentional.
- Vibe-vision does not handle conflict resolution between what the human wants and what
  is already in the roadmap. It surfaces the conflict and asks the human to decide.
- Vibe-vision does not estimate effort or prioritize between competing vision items.
  That is COORD's job once the artifacts land.

---

## Design

### The dialogue protocol

```
1. ORIENT: Read docs/aide/vision.md, docs/aide/roadmap.md, and all docs/design/*.md.
   Build a model of what the product currently is and what areas already have design docs.

2. LISTEN: The human speaks. Do not interrupt unless genuinely ambiguous.
   Let them finish a complete thought.

3. REFLECT: Post a structured reflection:

   [🌀 VIBE-VISION] I heard:
     What:    <one sentence — the capability or direction>
     Why:     <one sentence — the underlying need or goal>
     Layer:   <vision | roadmap | design doc | user doc>
     Affects: <which existing docs change; which new docs would be created>

   Is this right? What would you change?

4. ITERATE: Human corrects or confirms. Return to step 3 if corrected.
   Continue until human confirms with "yes", "right", "exactly", "ship it", or similar.

5. PROPOSE: Before writing any file, list all proposed artifacts:

   [🌀 VIBE-VISION] Proposing:
     - docs/design/06-X.md (new): <what it covers>
     - docs/X.md (new): user doc stub
     - docs/aide/roadmap.md: <what changes>

   Say "ship it" to commit. Say "change X" to adjust.

6. WRITE: Human approves → write all files → open PR (preferred) or push directly.
   PR title: "vision(<area>): <one sentence from the What field>"
```

### Artifact cascade order

```
docs/aide/vision.md        ← last (only if core identity changes)
docs/aide/roadmap.md       ← if new stage or stage scope changes
docs/design/<N>-<area>.md  ← always: one per feature area
docs/<feature>.md          ← always: user doc stub for user-facing behavior
```

Written bottom-up: user docs first (most concrete), then design docs, then roadmap,
then vision. This prevents over-generalizing a specific capability into a sweeping
vision change.

### What a vibe-vision session looks like

```
Human: I want users to be able to see what otherness is working on without
       digging into GitHub. Like a live dashboard.

[🌀 VIBE-VISION] I heard:
  What:    Users want a live view of autonomous team activity — in-flight work,
           recent ships, blockers — without needing GitHub access.
  Why:     Reduce cognitive distance between "I asked for X" and "X is being built."
  Layer:   design doc (new: observability / status surface)
  Affects: docs/design/06-status-surface.md (new stub)
           docs/status.md (new user doc)
           README.md observability table (update)

Is this right? What would you change?