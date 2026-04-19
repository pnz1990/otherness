# Spec: agents/autonomous-vision.md

> Item: 313 | Created: 2026-04-19 | Status: Active

## Design reference
- **Design doc**: `docs/design/18-autonomous-vision-synthesis.md`
- **Section**: `§ Future`
- **Implements**: `agents/autonomous-vision.md` — MODE: VISION, no dialogue step (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — `agents/autonomous-vision.md` exists with `## MODE: VISION`.**
The file must have the standard agent frontmatter and a `## MODE: VISION` block that
defines the DOCS zone constraint.

**O2 — The agent reads the corpus: design docs, ⚠️ stubs, sim output, metrics, roadmap.**
The corpus read section lists exactly what the agent reads and in what order, with
bash commands. This is not [AI-STEP] — it is concrete readable instructions.

**O3 — The agent synthesizes 3–5 `🔲 ⚠️ Inferred` items per run.**
The synthesis section defines the five synthesis patterns from doc 18: completion
frontier, pending ⚠️ stubs, unaccounted code, simulation signal, roadmap gaps.
For each pattern the agent checks whether an item from that pattern already exists in
the design docs before proposing a new one.

**O4 — The agent writes to `docs/design/` only, never to `docs/aide/`.**
vision.md, roadmap.md, and definition-of-done.md are never touched.

**O5 — validate.sh check 3 passes after adding the file.**
The file must be listed in the required-files check in validate.sh, or the check
must pass without listing it explicitly (since it's a new addition).

**O6 — Design doc 18 marks this ✅ Present.**

---

## Zone 2 — Implementer's judgment

- This is a HIGH tier file (new agent, not phases/*.md or standalone.md).
  Autonomous merge is permitted after CI passes.
- The synthesis logic is implemented as readable bash + python, not [AI-STEP] comments.
  The agent must be able to run without human guidance.
- For the first version: the synthesis is rule-based (pattern matching, not LLM calls).
  The agent reads the corpus and applies the five patterns algorithmically.

---

## Zone 3 — Scoped out

- LLM-assisted synthesis (rule-based only in first version)
- Cross-repo synthesis
- Synthesis from git history (design docs and metrics only)
