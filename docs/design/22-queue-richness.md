# 22: Queue Richness — Richer Sources Beyond Design Doc 🔲 Items

> Status: Active | Created: 2026-04-20
> Applies to: all projects using otherness

---

## The problem

COORD's queue generation reads exclusively from `🔲 Future` items in `docs/design/`
files. When those run dry — which happens after several active sessions — the queue
hits zero and the agent stalls, generating only docs-debt cleanup items or entering
standby. The human must run `/otherness.vibe-vision` to add direction.

This is an acceptable steady state only if the human is available. The vision
principle says the system must maintain its own momentum between human sessions.
A queue that depends on human-authored `🔲` items is not a self-sustaining queue.

---

## What "queue richness" means

A rich queue has items from multiple sources, ordered by fidelity:

| Priority | Source | Fidelity | Notes |
|---|---|---|---|
| 1 | `🔲 Future` in `docs/design/` | Highest — human-declared | Standard today |
| 2 | `🔲 ⚠️ Inferred` in `docs/design/` | Machine-observed, human-approved by non-removal | Already queued (COORD regex matches both) |
| 3 | Roadmap milestones not yet in design docs | Human-declared direction | Source: `docs/aide/roadmap.md` |
| 4 | PM §5h ⚠️ Observed — shipped code with no doc coverage | Machine-detected gap | Queued as kind/docs |
| 5 | PM §5c ⚠️ Inferred — competitive gaps | Machine-observed | Queued as kind/enhancement |
| 6 | SM §4g uncovered files | Machine-detected hygiene | Queued as kind/chore |

When source 1 is empty, COORD draws from source 2, then 3, and so on. The queue
never hits zero as long as any source has items.

---

## The roadmap source (source 3)

`docs/aide/roadmap.md` contains stage deliverables that are not yet tracked as
design doc items. When COORD generates a queue and design doc items are exhausted,
it reads the roadmap for unimplemented stages:

```python
# Pseudo-code for roadmap source
roadmap = open('docs/aide/roadmap.md').read()
stages = re.findall(r'^### Stage \d+.*?\n(.*?)(?=^### |\Z)', roadmap, re.MULTILINE|re.DOTALL)
for stage_content in stages:
    deliverables = re.findall(r'^- (.+)', stage_content, re.MULTILINE)
    for d in deliverables:
        if not is_done(d) and not is_queued(d):
            # Create issue from roadmap deliverable
            create_issue(f"feat: {d}", source="roadmap", design_ref="docs/aide/roadmap.md")
```

Roadmap items become issues with `area/agent-loop` label and `kind/enhancement`
type. They are lower priority than design doc items but higher than PM/SM-derived
items.

---

## The minimum queue depth trigger

When `QUEUE_REMAINING < 5` after any item completes, COORD immediately triggers
queue-gen from the next available source rather than waiting for the next session.
This is the minimum queue depth guard from `docs/design/21-session-throughput.md §1f`.

The trigger sequence:
1. Check design doc `🔲` items (including `⚠️ Inferred`)
2. If none: check roadmap for unimplemented deliverables
3. If none: check PM §5h/§5c issue backlog for ⚠️ items
4. If none: check SM §4g uncovered file candidates
5. If none: run autonomous vision synthesis inline (§4h trigger)
6. If none after synthesis: enter standby

---

## Present (✅)

- ✅ `🔲 Future` and `🔲 ⚠️ Inferred` items both queued by COORD regex (2026-04-19)
- ✅ PM §5h writes `⚠️ Observed` stub issues (2026-04-20, PR #337)
- ✅ PM §5c `write_inferred_stub()` writes `⚠️ Inferred` to design docs (2026-04-20, PR #337)
- ✅ SM §4g opens uncovered file issues (2026-04-20, PR #344)
- ✅ SM §4h autonomous vision trigger fires when queue empties (2026-04-20, PR #337)
- ✅ Minimum queue depth guard described in coord.md §1f (2026-04-20)

## Future (🔲)

- 🔲 `coord.md §1c`: roadmap source — when design doc items exhausted, read `docs/aide/roadmap.md` deliverables and create issues from unimplemented stages
- 🔲 `coord.md §1c`: source priority cascade — explicit ordered fallback: design docs → roadmap → PM §5h/§5c backlog → SM §4g backlog → autonomous vision
- 🔲 `coord.md §1f`: minimum queue depth guard executable — when QUEUE_REMAINING < 5, inline trigger next source (currently prose, not executable)

---

## Zone 1 — Obligations

**O1 — Source priority order is fixed: design doc > roadmap > PM/SM-derived.**
Items from `docs/design/` are human-declared intent. They must always be worked
before machine-inferred items. The cascade only descends when the higher source
is genuinely empty.

**O2 — Roadmap items become design doc stubs, not just issues.**
When COORD pulls a roadmap deliverable, it creates both a GitHub issue AND a stub
in `docs/design/` (if the relevant doc doesn't exist). This keeps the design
doc layer authoritative and the roadmap/issue layer derivative.

**O3 — Machine-derived items are always marked ⚠️ or kind/chore.**
The human must be able to identify at a glance which items came from machine
observation vs human intent. Never create a plain `🔲 Future` item autonomously
— always use `🔲 ⚠️ Inferred` or `🔲 ⚠️ Observed`.

**O4 — Queue generation never creates more than 20 items per cycle.**
The 20-item cap from doc 21 applies to the total across all sources, not per source.

---

## Zone 2 — Implementer's judgment

- Which roadmap stages to pull from: prefer the earliest incomplete stage to
  maintain coherent progression. Don't skip stages.
- How to determine "implemented": check if the deliverable text (first 40 chars)
  appears in any merged PR title or design doc ✅ Present item.
- Whether to create a new design doc for each roadmap item: if the item maps to
  an existing design doc area, add to that doc. If no doc exists, create a stub.

---

## Zone 3 — Scoped out

- Pulling items from external sources (Jira, Notion, etc.) — GitHub only
- Automatic stage completion marking in roadmap.md — human confirms stages done
- Cross-project queue sharing (each project has its own queue)
