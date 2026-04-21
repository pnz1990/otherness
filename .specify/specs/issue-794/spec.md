# Spec: COORD immediate queue refill when queue empties mid-session

**Item**: issue-794  
**Branch**: feat/issue-794  
**Date**: 2026-04-21

## Design reference
- **Design doc**: `docs/design/21-session-throughput.md`
- **Section**: `§ Future`
- **Implements**: COORD immediate queue refill when queue empties mid-session (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — After inline queue-gen creates new issues, they are immediately added to `state.json`.**  
Violation: newly created issues are not in `state.json.features` after inline queue-gen runs.

**O2 — `QUEUE_REMAINING` is re-computed after the refill so the §1f gate can detect new items.**  
Violation: `QUEUE_REMAINING` stays 0 after inline queue-gen creates issues, causing premature SM/PM exit.

**O3 — The state.json update is fail-open.**  
Violation: API error in state update blocks the session from reaching SM/PM.

---

## Zone 2 — Implementer's judgment

- Which labels to search for new issues (current: `otherness,kind/enhancement`).
- Whether to re-fetch from GitHub API or read from the inline queue-gen output (current: re-fetch from API — simpler and authoritative).
- How many issues to fetch (current: limit 20 — sufficient for a single inline queue-gen cycle).

---

## Zone 3 — Scoped out

- Claiming the first new item within the same §1f block (that happens naturally in the next §1e call after state.json is updated and QUEUE_REMAINING > 0).
- Updating metrics.md with the refill event (SM §4b handles metrics at batch end).
