# 18: Autonomous Vision Synthesis

> Status: Active | Created: 2026-04-19
> Applies to: otherness itself

---

## What this is

A self-directed vision agent that runs when the queue is empty and no human is
present. It reads everything the system already knows — design docs, competitive
observations, emergent code patterns, simulation output, metrics — and synthesizes
new `🔲 Future` items without requiring a human dialogue.

This is not a replacement for `/otherness.vibe-vision`. The human-initiated session
remains the highest-fidelity source of new direction because it carries intent that
cannot be derived from observation alone. This agent fills the silence between human
sessions. It keeps the loop alive.

---

## The two modes of vision expansion

| Mode | Trigger | Source of new direction | Output marker | Human needed? |
|---|---|---|---|---|
| **Human-initiated** | Human runs `/otherness.vibe-vision` | Human intent, shaped by dialogue | `🔲 Future` | Yes |
| **Autonomous synthesis** | Queue empty + no ⚠️ stubs pending + SM triggers | System's own knowledge corpus | `🔲 ⚠️ Inferred` | No — human confirms at own cadence |

The autonomous agent writes `🔲 ⚠️ Inferred` items. COORD queues them the same as
ordinary `🔲` items. The human can confirm, reshape, or remove them at the next
vibe-vision session or by directly merging the PR.

---

## The new agent: `agents/autonomous-vision.md`

A new agent file with `## MODE: VISION`. Not a conversation agent — no REFLECT step,
no human confirmation loop. It runs as a batch process, reads, synthesizes, and writes.

**It is still MODE: VISION.** It writes only to `docs/`. It never touches code,
agents, or scripts. The D4 boundary is preserved.

### What it reads

1. **All existing design docs** — current ✅ Present and `🔲 Future` items, what has
   been built and what has not. This gives it the current frontier.

2. **⚠️ Inferred stubs** (from PM §5c competitive observation) — flagged gaps that
   have not yet been converted to scoped Future items. These are its primary inputs.

3. **⚠️ Observed stubs** (from PM §5h emergent pattern detection) — code that exists
   with no design doc coverage. These signal undocumented capabilities that may point
   toward future directions.

4. **`scripts/sim-params.json`** — calibrated simulation parameters. Low boldness
   coefficient or high decay signals that the skills library is thin and new learning
   directions are needed.

5. **`docs/aide/metrics.md`** — recent batch history. Zero Type B rate (zero
   `needs_human`) for 5+ consecutive batches signals that the work has become
   mechanical — a sign that genuinely novel directions are needed.

6. **`docs/aide/roadmap.md`** — which stages are complete and which are not. The
   agent never synthesizes items for a stage that is explicitly gated.

### What it synthesizes

From the corpus above, the agent derives new `🔲 Future` items by asking:

- **Completion frontier**: what design docs are nearly complete (≥80% ✅)? What
  would the natural next capability be after the current frontier closes?
- **Pending signals**: which ⚠️ Inferred stubs have been sitting for >7 days without
  becoming scoped items? Convert them to `🔲 ⚠️ Inferred` Future items with scope.
- **Unaccounted code**: which ⚠️ Observed patterns suggest an undocumented direction
  the system has already started moving toward?
- **Simulation signal**: if arch_convergence is trending up, synthesize one
  architectural diversity item — something that would require a different kind of
  thinking than the last 10 shipped items.
- **Roadmap gaps**: which roadmap stages have no design doc coverage at all?
  Create a minimal stub.

The agent does not invent. It observes, connects, and names what is already latent
in the system's knowledge.

### What it writes

New or extended design docs in `docs/design/`. Each synthesized item is marked:

```markdown
- 🔲 ⚠️ Inferred: <capability description> — synthesized from <source>. (autonomous-vision, YYYY-MM-DD)
```

COORD treats `🔲 ⚠️ Inferred` identically to `🔲 Future`. The item enters the queue.
The `⚠️ Inferred` prefix is a flag to the human: this came from the system, not from
you. You can confirm it by letting it ship, or remove it at the next vibe-vision
session.

---

## When it runs

The SM phase triggers the autonomous vision agent when all of the following are true:

1. Queue is empty (0 todo, 0 in_review)
2. No ⚠️ Inferred or ⚠️ Observed stubs are pending conversion (all have been
   addressed — either converted to `🔲` items or removed)
3. PM §5g health is GREEN or AMBER (not RED — RED requires human judgment)
4. At least 3 batches have completed since the last autonomous vision run (rate limit
   to prevent runaway synthesis)

When triggered, the SM creates a `vision/auto-<date>` branch, reads and follows
`agents/autonomous-vision.md`, and merges the resulting design doc updates to main.
No human approval required for `🔲 ⚠️ Inferred` items — the merge itself is the
publication. The human discovers them on the next vibe-vision session or directly
in the design doc.

---

## The constraint: synthesis does not declare

The autonomous agent synthesizes candidates. It does not decide what the product
becomes. Items it generates are always marked `⚠️ Inferred`. A plain `🔲 Future`
item without the `⚠️` prefix means a human intentionally scoped it.

This distinction matters because:
- The implementation team (COORD/ENG/QA) treats both identically
- The PM team tracks the ratio of `⚠️ Inferred` to plain `🔲` items as a health
  signal: if >80% of Future items are `⚠️ Inferred`, the human has not directed
  the product in a long time — PM §5k posts a vibe-vision suggestion
- The simulation uses the ratio as a proxy for human engagement

---

## Present (✅)

- ✅ COORD queue gen: `🔲 ⚠️ Inferred` items matched by existing regex (no change needed); `is_done()` strips `⚠️ Inferred/Observed:` prefix before deduplication (PR #316, 2026-04-19)

## Future (🔲)

- 🔲 `agents/autonomous-vision.md` — new agent file, MODE: VISION, no dialogue step; reads corpus, synthesizes `🔲 ⚠️ Inferred` items, writes to docs/design/
- 🔲 SM phase trigger — when queue empty + no pending ⚠️ stubs + GREEN/AMBER health + ≥3 batches since last run: create `vision/auto-<date>` branch, run autonomous-vision agent, merge
- ✅ PM §5m: `⚠️ Inferred` ratio check — if >80% of Future items are ⚠️ Inferred, posts one vibe-vision suggestion per period; informational only (PR #315, 2026-04-19)

---

## Zone 1 — Obligations

**O1 — The autonomous vision agent writes only `🔲 ⚠️ Inferred` items, never plain `🔲`.**
Plain `🔲` is reserved for human-scoped intent. The marker distinction is the only
signal the human has about provenance.

**O2 — The agent never synthesizes items for stage-gated or speculative sections.**
Stage 5 (versioned release) is explicitly gated. Speculative items in doc 02 are
explicitly deferred. The agent reads these markers and skips them.

**O3 — The SM trigger has a rate limit: at least 3 batches between autonomous runs.**
Without this, the agent runs after every batch and floods the queue with machine-generated items, drowning human-scoped work.

**O4 — The `⚠️ Inferred` ratio is tracked and surfaced to the human when high.**
PM §5m reports the ratio. When >80% of all Future items are machine-generated, the
product has lost human direction. The system surfaces this exactly once per period.

**O5 — The agent does not modify `docs/aide/vision.md` or `docs/aide/roadmap.md`.**
These are the human's voice. Autonomous synthesis writes to `docs/design/` only.
The roadmap and vision are edited only by `/otherness.vibe-vision` sessions.

---

## Zone 2 — Implementer's judgment

- Whether the synthesis needs an LLM call or can be done with pattern matching:
  for the first version, rule-based pattern matching is sufficient. The agent
  converts ⚠️ Inferred stubs + roadmap gap detection into scoped items. LLM-assisted
  synthesis can come in a future iteration.
- How many items to synthesize per run: 3–5 maximum. Avoid flooding.
- Whether to open a PR or commit directly to main: a PR on `vision/auto-<date>`
  gives the human visibility. The PR merges automatically after CI (same as any
  other DOCS zone PR — no CRITICAL tier gatekeeping).

---

## Zone 3 — Scoped out

- Synthesizing items that require human validation before implementation (those stay
  in ⚠️ Inferred state until a human confirms)
- Autonomous modification of vision.md or roadmap.md
- LLM-assisted synthesis (first version is rule-based)
- Cross-project autonomous vision synthesis (otherness-self only in first version)
