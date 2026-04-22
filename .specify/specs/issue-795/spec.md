# Spec: Phase-Role Cognitive Diversity Preambles (issue-795)

## Design reference
- **Design doc**: `docs/design/31-stage-2-skills-expansion.md`
- **Section**: `§ Future`
- **Implements**: Phase-role cognitive diversity (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — Each phase file must have a cognitive-stance preamble injected near the top.**
The preamble must appear within the first 30 lines of the phase file, after the role identity
header. It consists of a single bolded line declaring the phase's cognitive stance:

- coord.md: `**Cognitive stance: optimistic incrementalist — What can be shipped quickly?**`
- eng.md: `**Cognitive stance: pragmatic builder — What is the minimal change that is correct?**`
- qa.md: `**Cognitive stance: adversarial skeptic — What assumption is wrong here?**`
- sm.md: `**Cognitive stance: historian — What pattern do we keep repeating?**`

**O2 — The preambles are ADD-ONLY additions to the existing phase content.**
No existing phase instructions are modified, moved, or removed.
The preambles are inserted immediately after the "Role identity" paragraph in each phase.

**O3 — validate.sh emits a WARNING (not an error) when a phase file lacks a "Cognitive stance:" line.**
This makes the absence of a preamble visible without blocking CI.
The warning fires only for coord.md, eng.md, qa.md, and sm.md.

**O4 — The preambles must not reference project-specific names, repos, or paths.**
They are generic guidance injected globally (CRITICAL tier — deploys to all projects).

---

## Zone 2 — Implementer's judgment

- The preamble is a single line, not a paragraph. Longer descriptions risk being ignored
  by agents with limited context. Short, memorable stances are more likely to influence framing.
- Position: after the "Role identity" block, before the first `---` separator.
- validate.sh check: use `grep` to check for "Cognitive stance:" in each phase file.
  Emit warning to stdout (not fail the check) so non-phase PRs are not blocked.

---

## Zone 3 — Scoped out

- Changing any existing phase instructions
- Adding per-item cognitive variance (e.g. "on chore items, ENG is less pragmatic")
- LLM temperature or model parameter changes
- Tracking QA rejection rates or cognitive diversity metrics
