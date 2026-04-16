# Future Ideas: Compounding Self-Improvement

> Status: Backlog — not scheduled. Review when otherness is running stably on ≥5 projects.

These ideas were identified on 2026-04-16 when thinking about how to make projects improve
exponentially rather than linearly. None of these are implemented. They are recorded here
so they are not forgotten.

The core insight: otherness currently learns from external open-source repos. The compounding
effect would be much stronger if it also learned from its own managed projects — without
those projects being hardcoded anywhere in the agent files.

---

## Idea 1: Learn from `[NEEDS HUMAN]` items across the portfolio

**What**: After N batches, analyze the last 20 closed `[NEEDS HUMAN]` issues across all
monitored projects. Extract recurring patterns. If a pattern appears ≥2 times, write or
extend a skill file in `~/.otherness/agents/skills/`.

**Why it compounds**: Every failure mode the agent encounters anywhere becomes a guard in
every future session everywhere. Failure rate decreases monotonically.

**Stays generic**: Skill files contain abstract patterns, not project names. The extraction
prompt explicitly strips project-specific details.

**Estimated impact**: Highest of all ideas. Direct feedback loop from failure to prevention.

---

## Idea 2: Cross-project pattern mining in the SM phase

**What**: Once per batch, sample last 10 merged PRs and last 10 resolved issues from each
monitored project. Ask: "What patterns appear in ≥2 projects?" Cross-project patterns
become skill candidates. Single-project insights stay local.

**Why it compounds**: Each new project added to the fleet contributes signal. n projects
produce n² potential pattern combinations — genuine network effect.

**Stays generic**: SM phase only sees structural patterns (fix types, QA rejection classes),
not domain-specific content.

---

## Idea 3: Difficulty ledger

**What**: A file `~/.otherness/agents/skills/difficulty-ledger.md` the agent appends to
whenever: (a) a task takes >3 QA cycles, (b) a `[NEEDS HUMAN]` occurs, (c) same bug class
appears twice. Each entry: abstract situation description + what resolved it + what guard
would have prevented it.

**Why it compounds**: Grows with every hard case. Agent consults it before every
implementation (already loads skills in Phase 2). Difficulty decreases over time.

**Stays generic**: Entries describe patterns, never project names.

---

## Idea 4: Internal learn sessions on your own portfolio

**What**: A variant of the learn trigger: once per 30 batches across all monitored projects,
read the last 50 merged PRs across the entire portfolio and extract generalizable patterns.
Same extraction prompt as external learn, but applied to real production PRs under your
constraints.

**Why it compounds**: Your own PRs have much higher signal-to-noise than external repos —
they reflect your specific model, CI, and review patterns. Generates skills that actually
work in your environment.

**Stays generic**: Extraction filter: "extract only patterns applicable to any software
project. Discard anything referencing a specific project name, domain, or codebase."

---

## Idea 5: PM phase proposes cross-project otherness improvements

**What**: Every N PM cycles, PM phase looks across all monitored projects and asks: "What
improvement to the agent loop, if made, would unblock the most projects simultaneously?"
Opens an issue on the otherness repo (not any individual project) proposing the improvement.

**Why it compounds**: Projects drive otherness improvements directly. More projects = more
diverse failure signals = better proposals. A genuine closed feedback loop.

**Stays generic**: Issues opened on otherness are about agent behavior, not project domains.

---

## Idea 6: Skill confidence scoring and deprecation

**What**: SM phase, once per N batches, checks each skill file: referenced recently? cited
in a PR? contradicted by a newer skill? Low-confidence skills get flagged; contradicted ones
get merged or deprecated.

**Why it compounds**: Skill quality improves over time. Deprecation prevents bloat.
Higher-quality skills → better ENG/QA decisions.

**Stays generic**: Scoring is structural (reference frequency, recency), not content-based.

---

## Implementation order (if we ever build these)

1. **Idea 1** (learn from `[NEEDS HUMAN]`) — highest leverage, smallest implementation
2. **Idea 3** (difficulty ledger) — small addition to existing phases, immediate value
3. **Idea 2** (cross-project SM mining) — medium complexity, requires fleet access in SM
4. **Idea 4** (internal portfolio learn) — variant of existing `/otherness.learn`, moderate work
5. **Idea 5** (PM cross-project proposals) — needs PM phase to have fleet visibility
6. **Idea 6** (skill confidence) — maintenance tooling, low urgency

## The math

Without these: `V(p, t) ∝ Q(t) × remaining_complexity(p, t)` — Q improves slowly from
external learning every 14 days. Linear improvement per project.

With these: `Q(t+1) = Q(t) + extract(failures(all_p, t)) + extract(successes(all_p, t))`
Q improves continuously from portfolio-wide signal. Rate of Q improvement scales with
number of projects. Each new project is additive signal. Super-linear (not quite exponential,
but much closer) improvement across the portfolio.

The ceiling is still model capability. But the gap between ceiling and current performance
closes much faster, and faster the more projects are running.
