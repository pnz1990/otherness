# Design Doc 59 — Nineteenth Vision Scan Pressure Gaps

**Vision scan date**: 2026-04-23
**Scan**: 19th autonomous run
**Pressure result**: SCAN 5 scores 5/5 via domain-noun matching (over-broad, per 50.3/53) — all five lenses remain genuinely open
**Backlog size**: 251 `🔲 Future` items across 62 design docs

---

## The problem

18 vision scans have run. Doc 58 added two precisely-scoped items (58.1–58.2). This
doc applies the same high-precision criterion: a gap must (a) be live today, (b) have NO
existing `🔲 Future` item covering it in any of the 62 design docs — verified by exhaustive
keyword search across all 251 items, and (c) fix directly reduces failure under one of the
five pressure lenses.

After that exhaustive search, two genuinely absent gaps were found. The remaining pressure
failures are already covered by items in docs 46–58; those items have not yet shipped.
This doc does NOT re-describe covered gaps. It adds only what is demonstrably absent.

---

## Present (✅)

*(No items shipped yet — doc created by this scan)*

---

## Future (🔲)

### Lens 1 — Reliability: merged-then-reverted PRs are invisible to the meaningful-PR accounting

- 🔲 59.1 — SM §4b tracks `meaningful_prs` per session to measure delivery quality. The
  `meaningful_prs` count is populated at session close by counting merged PRs with `feat/`
  prefix or that promote a `🔲 Future` design doc item to `✅ Present`. But this count is
  computed at merge time — it does not account for the case where a merged PR is
  **subsequently reverted** (a revert PR merged in the same or next session). A reverted
  PR is not a shipped feature: the codebase returns to its pre-merge state, the design doc
  item remains `🔲 Future`, and the session that merged it receives full credit for a
  meaningful PR that produced no lasting improvement. The result: `meaningful_prs` and
  `vision_prs` can both be positive for a session that effectively shipped nothing because
  QA or human oversight identified a defect and rolled back the change. The pressure
  context states: "sessions still fail silently, produce housekeeping PRs with no real
  feature content." A reverted-PR session is the mirror failure: it appears to ship real
  content but the content does not survive. SM §4b must: (1) on each session close, query
  merged PRs in the last 7 days for any whose title starts with `Revert "` — these indicate
  a rollback of a previously-merged PR; (2) for each revert PR found, identify the original
  PR number (from the revert title format `Revert "PR title"`); (3) if the original PR was
  counted in the session's `meaningful_prs`, decrement `meaningful_prs` by 1 and write a
  `reverted_meaningful_prs` column to `metrics.md`; (4) if `reverted_meaningful_prs > 0`
  for a session, add a note to the SM §4f report: "⚠️ {N} meaningful PR(s) reverted —
  net delivery is lower than reported." This prevents the health signal from reporting a
  productive session that was immediately rolled back. Without this correction, the
  reliability metric is structurally over-counted: every reverted feature inflates the
  `meaningful_prs` ledger by 1 while contributing 0 lasting improvement. No existing item
  in any doc covers this accounting correction — doc 31 covers QA REJECTION RATE (PRs
  rejected before merge) but not the post-merge revert case. Doc 46.19 covers QA behavioral
  gate (rejecting whitespace-only PRs) but not post-merge revert accounting. This item
  is the only coverage for the `merged-then-reverted = not meaningful` semantic gap.

### Lens 2 — Honesty: state.json has no write-confirmation loop — ghost locks are silently created

- 🔲 59.2 — COORD §1e claims an item by writing `state: in_progress` to `.otherness/state.json`
  on the `_state` branch via `git push`. If the push fails after the local write but before
  the remote confirms (network partition, branch divergence, stale credentials), the item
  is `in_progress` locally but the remote `_state` still shows `todo`. The next session
  reads the remote `_state`, does not see the lock, and also claims the same item — two
  sessions attempt to implement the same issue concurrently. SM §4a's stale-branch
  watchdog reclaims abandoned branches after 60 minutes, but the duplicate-claim window
  (up to 60 minutes) can result in two concurrent `feat/` branches for the same issue, a
  merge conflict at QA, and a ghost `in_progress` entry that never resolves. The current
  loop has no mechanism that confirms the push succeeded before treating the claim as
  authoritative.

  COORD §1e must verify the push succeeded by re-reading `_state` immediately after push:
  ```bash
  gh api repos/$REPO/contents/.otherness/state.json?ref=_state \
    --jq '.content' | base64 -d | python3 -c "
  import sys, json
  state = json.load(sys.stdin)
  item = next((i for i in state.get('queue',[]) if i['issue']==$ISSUE_NUM), None)
  print(item['state'] if item else 'NOT_FOUND')
  "
  ```
  If the re-read shows `todo` (push did not land): COORD must retry the push with rebase
  (max 2 retries). If all retries fail: skip the item, log the failure as
  `eng_fail_reason: state_write_failed`, and exit cleanly without leaving a ghost lock.

  This item is distinct from every existing item in the 251-item corpus:
  - Doc 35 covers `state.json` write atomicity in the context of `meaningful_prs` counting.
  - Doc 48.2 covers stale watchdog adding root-cause comments before re-release.
  - Neither covers the specific COORD §1e write-confirmation loop that prevents ghost locks
    from being created in the first place.

  The honesty failure: a system that reports `GREEN` health while running sessions that
  silently create ghost `in_progress` locks (and thus phantom "working" sessions) is
  structurally dishonest. The SM watchdog eventually cleans up the ghost — but between
  creation and cleanup, the health signal shows the item as `in_progress` (implying work
  is happening) when no work is occurring. The write-confirmation loop at COORD §1e
  converts this from a silent, delayed-detection failure to an immediate, prevented failure.

---

## Zone 1 — Obligations

| # | Obligation |
|---|---|
| 59.1 | SM §4b must query for revert PRs (`title starts with "Revert \""`) on each session close and decrement `meaningful_prs` for any reverted feature PRs. Write `reverted_meaningful_prs` column to `metrics.md`. Include revert note in SM §4f report when count > 0. |
| 59.2 | COORD §1e must re-read `_state` after each `git push` to confirm the state write landed. If re-read shows `todo`: retry push with rebase (max 2 retries). If all retries fail: skip item, write `eng_fail_reason: state_write_failed` to state.json, exit cleanly. Never proceed with a claim when the push confirmation fails. |

## Zone 2 — Implementer's judgment

- 59.1: the 7-day revert scan window (not just current session) is intentional — a PR
  merged at the end of one session may be reverted at the start of the next. Using 7 days
  catches cross-session reverts. A revert PR is identified by title prefix `Revert "` —
  this is the standard GitHub auto-generated revert PR title format. If the revert title
  does not contain a recognizable original PR number or title, SM §4b must log a warning
  but not decrement (conservative: don't decrement on ambiguous reverts).
- 59.2: the re-read check adds at most one `gh api` call per claim (plus up to 2 retries
  on failure). Expected overhead: <2 seconds on success, <10 seconds on failure with retry.
  The rebase retry preserves any intervening state changes from parallel sessions. If the
  rebase itself fails (conflicts), exit cleanly — do not force-push. The fail-safe is always
  "do nothing rather than corrupt state."

## Zone 3 — Scoped out

- 59.1 does NOT retroactively adjust historical `metrics.md` rows. It applies from the
  session that implements it forward. Historical under-counting of reverted PRs is
  acceptable given the low frequency of production reverts.
- 59.1 does NOT trigger any automatic remediation when a revert is detected — it is a
  measurement correction, not a control signal. The decrement updates the metric and the
  report comment; no automatic re-claim of the reverted item is performed.
- 59.2 does NOT redesign the `_state` branch locking model. It adds a confirmation check
  at the point of write. The broader distributed-lock design (doc 15) remains unchanged.
- 59.2 does NOT apply to SM's state writes (e.g., advancing `state: done`, updating
  metrics). It applies only to COORD §1e's claim-write (`state: in_progress`), which is
  the highest-risk write because it creates the lock that can become a ghost.
