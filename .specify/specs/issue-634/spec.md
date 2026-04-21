# Spec: SM §4b Session Defect Diagnosis

## Design reference
- **Design doc**: `docs/design/21-session-throughput.md`
- **Section**: `§ Future`
- **Implements**: Session defect diagnosis: when a session completes with 0 meaningful items (only metrics commits, chores, or SM/PM housekeeping), SM §4b must open a `kind/bug` issue with the diagnosed root cause (🔲 → ✅)

---

## Zone 1 — Obligations

**O1**: When `MEANINGFUL_PRS == 0` for the current session (no design-doc-backed PRs merged), SM §4b MUST open a `kind/bug` issue diagnosing the root cause.

**O2**: The diagnosis must categorize the root cause from this ordered list:
1. `queue-source-exhausted` — no 🔲 Future items in docs/design/, roadmap has no incomplete stages
2. `all-items-blocked` — all todo items in state.json have `blocked` label or failed 3+ attempts
3. `ci-red` — main branch CI has been red, blocking merges
4. `vision-pressure-too-low` — queue exists but all items are `kind/chore` or `kind/docs` (no enhancement items)
5. `unknown` — cannot determine root cause from available signals

**O3**: The issue MUST NOT be opened if one was already opened for the same session (deduplicate by checking for open issues with title prefix `[DEFECT]`).

**O4**: The issue title format: `[DEFECT] Session completed with 0 meaningful PRs — <root-cause>`.

**O5**: The defect issue body MUST include: session ID, batch number, vision_prs, merged count, root cause name, and a concrete next-action recommendation for each root cause.

**O6**: The defect issue MUST be labeled `kind/bug,otherness,priority/high,area/agent-loop`.

**O7**: This check runs only when `MEANINGFUL_PRS == 0`. Sessions that shipped ≥1 meaningful PR are healthy — no issue is opened.

---

## Zone 2 — Implementer's judgment

- Whether to fetch MEANINGFUL_PRS from env (already set in §4b) or recompute: use env var if set, avoid redundant API calls.
- Whether to check all 5 root causes or short-circuit at first match: short-circuit at first match for efficiency.
- How to detect "queue-source-exhausted": scan docs/design/ for any 🔲 items not in state.json done list; if 0 found AND roadmap has no incomplete stages → exhausted.

---

## Zone 3 — Scoped out

- Auto-healing after diagnosis (that is the responsibility of the next session's COORD)
- Tracking defect streaks (separate design doc 21 item for housekeeping-streak)
- Opening defect issues for every `chore-only` session (too noisy; only when MEANINGFUL_PRS == 0)
