# 45: Distil and Simplify — Reliability Over Features

> Status: Active | Created: 2026-04-22
> Applies to: otherness itself — the agent loop and all managed projects

---

## The problem in one sentence

We have 9,788 lines of agent phase instructions that run every session. The three things
the human actually needs — a working core workflow, a working GitHub project layer, and
working metrics — are broken. The complexity is not delivering the reliability.

---

## The competitor diagnosis

spec-kitty (1,104 stars, actively used by teams) has under 3,000 lines total for its
entire project. Its core workflow is six steps that execute 100% of the time:

```
specify → plan → tasks → implement → review → merge
```

Every step has: a CLI command, an expected output artifact, and a clear gate to the next
step. Nothing ambiguous. Nothing that requires the agent to "interpret loosely."

Otherness has 5,015 lines in sm.md alone, with 882 lines devoted to a metrics section
and 628 lines devoted to a simulation calibration section that has never demonstrably
changed agent behavior. The core loop is buried. The critical mechanisms — issue close,
board status, milestone assignment — break silently while complex, rarely-triggered logic
runs fine.

**Simple systems that work 100% of the time deliver more value than complex systems that
work 60% of the time.** This is not a new insight. It is the oldest engineering principle.
We have been violating it systematically.

---

## The three things that are air, food, and water

These must work on every single run, every single session, without exception. A session
where any of these fails is a broken session regardless of what else it shipped.

### 1. The core workflow loop

```
Queue item claimed
      ↓
Discovery questions answered (spec ready)
      ↓
Spec written (Zone 1/2/3, design doc reference)
      ↓
tasks.md written ([AI]/[CMD] typed)
      ↓
Code implemented (TDD, surgical changes)
      ↓
PR opened (Closes #N in body, Signed-off-by in commit)
      ↓
CI passes (all checks green, QA verified)
      ↓
PR merged
      ↓
Issue closed
      ↓
Board Status → Done
      ↓
Health signal posted
```

Every arrow in this chain must be executable code, not a comment. If any step fails,
the loop must surface the failure clearly — not continue silently and report GREEN.

### 2. GitHub project management layer

- Every new issue created by COORD gets: `Status: Todo` on the board, the active milestone assigned.
- Every item claimed by ENG: `Status: In Progress`.
- Every PR opened by ENG: `Status: In Review`.
- Every PR merged by QA: issue closed, `Status: Done`.

This must work on every project, every session, 100% of the time. Right now: 27 open
issues today on kardinal-promoter with no milestone. Zero issues closed as "completed."
This is the human's steering wheel. It must work.

### 3. Metrics — the minimum viable signal

The human needs to answer these questions from the batch report without opening any links:

1. Did meaningful work ship this session? (Y/N + what)
2. What is in the queue? (N items, top 3 titles)
3. Is anything blocking? (Y/N + what)

That's it. Not 882 lines of metrics. Three answers. If the human cannot answer these
three questions from a 30-second read of the batch report, the metrics system has failed.

---

## The distil-and-simplify principle

> **When adding to the agent loop, ask: does this make the core workflow more reliable,
> or does it add a new way for the loop to fail?**

Every section added to sm.md, coord.md, eng.md, or qa.md is a new failure surface. The
agent reads all of it. When a section is complex, ambiguous, or conditionally-triggered,
the agent interprets it loosely — sometimes correctly, often not.

The test for any new section:
- Is it in the critical path (runs every session)? → It must be executable shell/Python.
- Is it periodic (runs every N sessions)? → It must have a hard skip guard and fail silently.
- Is it aspirational (describes intent, not action)? → It does not belong in the phases. It belongs in a design doc.

**[AI-STEP] is a red flag.** A phase section that contains `[AI-STEP]` as its only executable content is asking the agent to decide what to do. The agent will decide differently every session. This is non-determinism in a system that must be reliable.

---

## The simplification cycle

Every 30 batches (approximately monthly), otherness runs a simplification cycle:

1. **Identify dead weight**: count [AI-STEP] sections in all phase files. Any section
   that is >50% [AI-STEP] comments is a candidate for removal or rewrite.

2. **Identify non-executing sections**: scan the last 30 session logs for sections that
   never produce output. A section that doesn't fire in 30 sessions is dead weight.

3. **Distil**: remove or compress sections that are failing the tests above. Move
   aspirational content to design docs. Replace [AI-STEP] with executable code or delete.

4. **Verify core works**: after simplification, run `/otherness.run` on a test project
   and verify the chain from claim → closed issue → board Done executes completely.

The simplification cycle is not a new feature. It is maintenance. It must be scheduled
and executed like any other item in the queue.

---

## Present (✅)

- ✅ Design doc created (this file) (2026-04-22)

## Future (🔲)

- 🔲 45.1 — Audit and reduce sm.md: identify the top 5 sections by line count that have never demonstrably changed behaviour. Compress or remove them. Target: sm.md under 2,000 lines.
- 🔲 45.2 — Make the core workflow chain fully executable: every arrow in the core loop above must be a bash/Python command, not an [AI-STEP] comment. Count [AI-STEP] occurrences in coord.md, eng.md, qa.md — every one is a reliability debt item.
- ✅ 45.3 — Board status and milestone: fix the gap (27 open issues with no milestone today). The COORD issue-creation block must include `gh issue edit --milestone` and `gh project item-add` as non-optional, always-running commands. (PR #925)
- 🔲 45.4 — Minimum viable batch report: replace the 882-line metrics section with a 50-line block that answers exactly three questions: did meaningful work ship (Y/N + what), what is in the queue (N items), is anything blocking (Y/N + what). The current section generates elaborate output no human reads.
- 🔲 45.5 — Simplification cycle scheduled: add to SM §4a triage — every 30 batches, open a `kind/chore priority/high` issue: "Simplification cycle: distil sm.md, coord.md, eng.md, qa.md." This item goes to the top of the queue.
- 🔲 45.6 — [AI-STEP] elimination: replace every [AI-STEP] in coord.md and eng.md with either executable code or deletion. No phase section may contain [AI-STEP] as its only content.

- 🔲 45.7 — Step A per-step timeout (deferred — add after 45.1-45.6 complete)
- 🔲 45.8 — Phase file line count cap (deferred — add after 45.1 ships)
---

## Zone 1 — Obligations

**O1 — The core workflow chain runs completely on every session or the session is AMBER.**
A session that claims an item, does work, and does not close the issue and set board Done
is a broken session. It must not report GREEN. Period.

**O2 — The batch report answers the three questions in one read.**
If the human must open PRs, check the board, or read log lines to answer (1) did work ship,
(2) what is queued, (3) is anything blocking — the report has failed. Redesign until it
answers all three in the comment body.

**O3 — Every [AI-STEP] in a critical-path section is a reliability debt.**
Each one must be tracked and resolved. A phase file that has grown [AI-STEP] content is
accumulating debt. The simplification cycle clears it.

**O4 — Complexity added must be justified by reliability gained, not feature gained.**
"This would be useful if it works" is not sufficient justification. "This makes the core
loop more reliable" is. New sections in phase files must pass this test before merging.

**O5 — Simplicity is a feature.** The human's ability to read the instructions and predict
what the agent will do is a first-class property. A 5,000-line SM phase that no human can
fully read is not a feature — it is a liability.

---

## Zone 2 — Implementer's judgment

- Starting point for 45.1 (sm.md reduction): the simulation calibration section (628 lines,
  §4d+4e) and the cross-project learning section (647 lines, §4c) have the highest line counts
  and the lowest evidence of actually changing behaviour. Start there.
- The metrics section (882 lines, §4b) is large but some of it is valuable. Extract the three
  questions, verify they're answered, delete everything else. The elaborate metrics tables no
  one reads do not need to be in the agent loop — they belong in a dashboard or report doc.
- [AI-STEP] elimination order: coord.md first (it runs on every session, any AI-STEP there
  means the claim logic is non-deterministic), then eng.md, then qa.md.

---

## Zone 3 — Scoped out

- Rewriting the phases from scratch (too much risk, incremental reduction is safer)
- Removing PM phase entirely (valuable for competitive awareness, just needs trimming)
- Changing the D4 architecture (three zones, design docs, specs — these are working)
- Removing all conditional/periodic logic (some is correct, it just needs hard guards)
