# Future Ideas: Compounding Self-Improvement

> Status: Backlog — not scheduled. Review when otherness is running stably on ≥5 projects.
>
> Ideas in this file were moved here from GitHub issues because they are too large, too
> architectural, or too early to implement autonomously. They are preserved so they are
> not forgotten and can be revisited when the time is right.

These ideas were identified on 2026-04-16 when thinking about how to make projects improve
exponentially rather than linearly. None of these are implemented. They are recorded here
so they are not forgotten.

The core insight: otherness currently learns from external open-source repos. The compounding
effect would be much stronger if it also learned from its own managed projects — without
those projects being hardcoded anywhere in the agent files.

---

## ✅ Idea 1: Learn from `[NEEDS HUMAN]` items — COVERED (SM §4c cross-project mining, PR #173, 2026-04-17)

**What**: After N batches, analyze the last 20 closed `[NEEDS HUMAN]` issues across all
monitored projects. Extract recurring patterns. If a pattern appears ≥2 times, write or
extend a skill file in `~/.otherness/agents/skills/`.

**Why it compounds**: Every failure mode the agent encounters anywhere becomes a guard in
every future session everywhere. Failure rate decreases monotonically.

**Stays generic**: Skill files contain abstract patterns, not project names. The extraction
prompt explicitly strips project-specific details.

**Estimated impact**: Highest of all ideas. Direct feedback loop from failure to prevention.

---

## ✅ Idea 2: Cross-project pattern mining — COVERED (SM §4c implementation, PR #173, 2026-04-17)

**What**: Once per batch, sample last 10 merged PRs and last 10 resolved issues from each
monitored project. Ask: "What patterns appear in ≥2 projects?" Cross-project patterns
become skill candidates. Single-project insights stay local.

**Why it compounds**: Each new project added to the fleet contributes signal. n projects
produce n² potential pattern combinations — genuine network effect.

**Stays generic**: SM phase only sees structural patterns (fix types, QA rejection classes),
not domain-specific content.

---

## ✅ Idea 3: Difficulty ledger — IMPLEMENTED (PR #172, 2026-04-17)

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

## ✅ Idea 5: PM phase proposes cross-project otherness improvements — IMPLEMENTED (PR #177, 2026-04-17)

**What**: Every N PM cycles, PM phase looks across all monitored projects and asks: "What
improvement to the agent loop, if made, would unblock the most projects simultaneously?"
Opens an issue on the otherness repo (not any individual project) proposing the improvement.

**Why it compounds**: Projects drive otherness improvements directly. More projects = more
diverse failure signals = better proposals. A genuine closed feedback loop.

**Stays generic**: Issues opened on otherness are about agent behavior, not project domains.

---

## ✅ Idea 6: Skill confidence scoring and deprecation — IMPLEMENTED (PR #181, 2026-04-17)

**What**: SM phase, once per N batches, checks each skill file: referenced recently? cited
in a PR? contradicted by a newer skill? Low-confidence skills get flagged; contradicted ones
get merged or deprecated.

**Why it compounds**: Skill quality improves over time. Deprecation prevents bloat.
Higher-quality skills → better ENG/QA decisions.

**Stays generic**: Scoring is structural (reference frequency, recency), not content-based.

---

## Implementation order (if we ever build these)

> **Status as of 2026-04-17**: 6/9 ideas implemented. Items below updated to reflect current state.

1. ✅ **Idea 1** (learn from `[NEEDS HUMAN]`) — COVERED by SM §4c (PR #173)
2. ✅ **Idea 3** (difficulty ledger) — DONE (PR #172)
3. ✅ **Idea 2** (cross-project SM mining) — COVERED by SM §4c (PR #173)
4. **Idea 4** (internal portfolio learn) — NEXT UP: triggers at sm_cycle_count=30 (currently 16)
5. ✅ **Idea 5** (PM cross-project proposals) — DONE (PR #177)
6. ✅ **Idea 6** (skill confidence) — DONE (PR #181)
7. **Idea 8** ✅ — COVERED by SM §4c (PR #173)

**Remaining (deferred/large)**:
- **Idea 4**: At sm_cycle=30. Variant of `/otherness.learn` using own portfolio PRs. Scheduled.
- **Idea 7**: Event-sourced state — large architectural change. Deferred until state corruption observed.
- **Idea 9**: otherness as a service — requires cloud infrastructure. Deferred until >10 repos.

## The math

Without these: `V(p, t) ∝ Q(t) × remaining_complexity(p, t)` — Q improves slowly from
external learning every 14 days. Linear improvement per project.

With these: `Q(t+1) = Q(t) + extract(failures(all_p, t)) + extract(successes(all_p, t))`
Q improves continuously from portfolio-wide signal. Rate of Q improvement scales with
number of projects. Each new project is additive signal. Super-linear (not quite exponential,
but much closer) improvement across the portfolio.

The ceiling is still model capability. But the gap between ceiling and current performance
closes much faster, and faster the more projects are running.

---

## Idea 7: Event-sourced state (was GitHub issue #118)

**What**: Replace `state.json` mutable snapshot with an append-only `events.jsonl` log on
the `_state` branch. Each action appends one line:
```json
{"ts":"2026-04-17T00:45:09Z","session":"STANDALONE-900","event":"item.claimed","item":"900-playwright","branch":"feat/900-playwright-e2e-fix"}
```
Current state is derived by replaying the log. Appends don't conflict → true parallel safety
without field-level merge hacks.

**Why it matters**: The current field-level merge (PR #107) mostly works but has edge cases.
Event sourcing eliminates the problem class entirely. Gives full audit trail and replay.

**Why deferred**: Full rewrite of the state management layer — the most sensitive part of
standalone.md. The field-level merge fix is good enough for current scale. Revisit when
parallel session count exceeds ~10 or when state corruption is observed in production.

**Prior art**: Martin Fowler Event Sourcing (2005), Apache Kafka log architecture.

---

## ✅ Idea 8: Cross-project learning loop — IMPLEMENTED (PR #173, 2026-04-17)

> Note: This overlaps significantly with Ideas 1 and 4 above. Issue #120 is the GitHub
> version of the same concept — closed to avoid duplication.

**Extended design from issue #120**:

The SM phase has a stub for cross-project pattern mining (phases/sm.md §4c). The stub
fires every 5 SM cycles and collects needs-human items. What it doesn't do yet:
- Actually extract patterns from the collected items
- Write generalizable patterns to skill files
- Do this across the full portfolio (not just the current project)

The full implementation requires:
1. SM phase reads `monitor.projects` from otherness-config.yaml
2. For each project: fetch last 10 closed `[needs-human]` issues
3. Ask the model: "What generalizable pattern do ≥2 of these represent?"
4. If pattern found: append to `~/.otherness/agents/skills/difficulty-ledger.md`
5. If pattern is entirely novel: open a PR on the otherness repo

The stub in sm.md is ready. The AI step inside it needs to be written.

---

## Idea 9: otherness as a service (was GitHub issue #122)

**What**: Move agent execution from local machine to cloud infrastructure.
- Trigger: GitHub webhook → cloud function → ephemeral container → run `/otherness.run` → tear down
- State: already in `_state` branch — no database needed
- Auth: GitHub App installation token per repo (rate limits per-installation, not per-user)
- Billing: per-agent-minute or per-PR-merged

**Why it matters**: Agents currently stop when the laptop closes. At 10+ projects, requires
10+ always-on machines. This is the path every production autonomous coding product
(Devin, Jules, OpenHands Cloud) has taken.

**Why deferred**: Requires a hosting layer outside this repo. The agent instructions
(standalone.md) don't need to change — the container just runs them. The main design
consideration: worktree paths like `../<repo>.<item>` won't work in containers — needs
an absolute path convention. File an issue when ready to build.

**Constraint to preserve**: standalone.md must never assume local execution — no hardcoded
absolute paths, no `~/` assumptions in core logic. The v2 refactor already avoids this.

