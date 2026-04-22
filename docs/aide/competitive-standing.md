# otherness Competitive Standing

> Updated by PM §5c every 10 batches. One row per comparison cycle per comparator.
> Scores are 0–3 per dimension. `otherness_score/comparator_score` format.
> Produced by PM §5c per design doc 17 §Future O1 (PR: feat/issue-889).

---

## Rubric Dimensions

| Dimension | What it measures |
|---|---|
| `reliability` | Does the system ship PRs every run? (core-loop stability) |
| `self-improvement` | Does the agent get measurably smarter over time? (skills, learn sessions) |
| `onboarding` | Can a new project start in <30 minutes? (setup friction) |
| `visibility` | Can a human read system health in 30 seconds? (status command, health signal) |

**Scale**: 0 = not present / 1 = partial / 2 = working / 3 = excellent

---

## Comparison Log

| Date | Batch | Comparator | reliability | self-improvement | onboarding | visibility | delta |
|---|---|---|---|---|---|---|---|
| 2026-04-22 | 10 | spec-kitty | 2/2 | 3/1 | 2/2 | 2/1 | +self-improvement, +visibility |
| 2026-04-22 | 10 | Hermes | 2/2 | 3/2 | 2/1 | 2/1 | +self-improvement, +onboarding, +visibility |

---

## How to read this

Each row answers: "At this batch, how did otherness compare to this system on each dimension?"

`otherness_score/comparator_score` — a score of `3/1` means otherness outperforms on this dimension.
A `delta` of `+self-improvement` means otherness scored higher on that dimension.

PM §5c appends a new row every 10 batches. SM §4b reads the latest row and includes a one-line
competitive summary in the health comment.
