# 43: Session Watchdog and Timeout Recovery — Never Exit Silently

> Status: Active | Created: 2026-04-21
> Applies to: otherness itself and all managed projects

---

## The problem

A scheduled GitHub Actions session runs for up to 6 hours. Within that window, the
agent loop claims an item, implements it, QA-reviews it, and merges it — or fails
and exits. The failure modes that are NOT currently detected:

1. **Mid-session stall**: the agent has claimed an item but 90+ minutes pass with no
   PR open, no commit pushed. The session is frozen — LLM context limit hit, tool
   call hung, GitHub API rate limit silently throttling. The runner times out and exits
   with no PR, no state write, no error message visible on the report issue.

2. **Graceful exit without artifact**: the agent loop completes normally (reaches THE
   LOOP bottom), but 0 PRs were merged and 0 PRs are open. The exit is "clean" but
   the batch produced nothing. SM §4f writes a GREEN health signal because `ci_red_hours
   == 0` and `needs_human == 0` — the absence of work looks like a clean run.

3. **Last-item partial completion**: ENG completes implementation on the last item
   before session timeout. The commit exists but the PR was never opened, or the PR
   was opened but QA never ran. The item is `assigned` in state.json but the stale
   watchdog won't clear it until the next session — which is 6 hours later.

4. **Session start without state sync**: a session starts but `_state` branch pull
   fails silently (network issue, branch lock, API timeout). The session reads a stale
   `state.json`, re-claims already-assigned items, creates duplicate branches, and
   produces duplicate PRs that QA must close.

None of these produce a visible error. From GitHub's perspective, the session ran and
completed. The operator has no signal that the session was unproductive.

---

## What "fixed" looks like

A watchdog check runs at the end of every phase boundary (COORD → ENG → QA → SM).
If the session has consumed >80% of its expected budget (time or items) with 0 merged
PRs, the session self-diagnoses before exiting. The SM phase always runs, even in
partial sessions — because SM's state write is the only external artifact that
distinguishes "session ran" from "session stalled."

---

## Present (✅)

*(Nothing shipped yet.)*

---

## Future (🔲)

- 🔲 43.1 — `standalone.md` THE LOOP: add phase-boundary budget check — after each phase completes, check elapsed time (from `SESSION_START_EPOCH` env var set at loop entry) against `maqa.session_budget_minutes` (default: 90). If elapsed > 80% of budget AND `prs_merged_this_session == 0`: skip to SM phase immediately, bypassing any remaining ENG/QA work. SM must write `session_outcome: budget_exhausted` and post `[⚠️ BUDGET]` to report issue with diagnosis: what phase was active, how many items were attempted, last PR status. Without this check, a mid-session stall is indistinguishable from a productive session until the next session reads stale state. ⚠️ Inferred from reliability lens: sessions still fail silently; a truly reliable system ships at least one meaningful PR every single run without exception — the current loop has no in-session timeout watchdog.

- 🔲 43.2 — `standalone.md` STARTUP: `_state` pull verification with retry and abort-on-fail — the session start pulls `_state` branch before reading `state.json`. This pull can fail silently if the branch is locked, the API is rate-limited, or the network drops. Current behavior: the agent continues with whatever `state.json` is on disk (potentially stale from the last session). Required behavior: STARTUP must (1) attempt `git fetch origin _state:_state` with a 30-second timeout; (2) on failure: retry once after 15 seconds; (3) on second failure: write `state_sync_failed: true` to a local temp file and skip COORD (go directly to SM with `session_outcome: startup_failed`). A session that cannot sync state must NOT claim any items — it risks duplicate claims, race conditions, and stale data. This is a correctness gate, not a performance optimization. ⚠️ Inferred from reliability lens: session start without state sync produces duplicate branches and stale claims; the current startup has no explicit sync-verification step.

- 🔲 43.3 — SM §4f: distinguish `session_outcome: silent` vs `budget_exhausted` vs `startup_failed` — the current silent-session detection (doc 35 §SM §4f) detects 0-PR sessions but treats them all identically. Three distinct causes have different remediation paths: (a) `silent` (budget not exhausted, startup ok, but 0 PRs) → chore-queue or ENG zero-diff problem; (b) `budget_exhausted` → session ran too long per item, needs `session_item_limit` reduction or item complexity reduction; (c) `startup_failed` → infrastructure problem, needs human attention on secrets/network. SM §4f must write the specific sub-type to `state.json.session_outcome` and surface it in the health comment. A human who sees "AMBER — budget_exhausted (3 consecutive)" knows to reduce item scope. A human who sees "AMBER — startup_failed (2 consecutive)" knows to check GitHub Actions secrets. The merged signal provides no actionable diagnosis. ⚠️ Inferred from reliability lens: the current loop detects 0-PR sessions but cannot distinguish the three different causes — the remediation action is different for each, but the signal is the same.

- 🔲 43.4 — `standalone.md` THE LOOP: last-item partial-completion recovery — when the session exits with an `assigned` item (item state is `assigned` in state.json at loop exit), the stale watchdog in the next session resets it to `todo` after the stale timeout. But the stale timeout is `maqa.stale_timeout_minutes` (default: 120 minutes) — meaning the next session (6 hours later) arrives to find the item already reset. The current watchdog correctly handles this. The gap: if ENG completed implementation (commits exist on the branch) but QA never ran, the commits are abandoned. The next session doesn't know commits exist and may re-implement from scratch, creating a diverged branch. COORD §1d stale reset must: (1) before resetting an `assigned` item to `todo`, check if a `feat/<issue_number>` branch exists with commits newer than the assignment time; (2) if commits exist: re-assign the item and jump directly to QA phase (skip ENG) with a `[RECOVERY: partial-session]` note. This converts a 100% loss to a partial recovery — the implementation work is preserved. ⚠️ Inferred from reliability lens: when a session times out mid-QA, all ENG work is discarded and repeated in the next session; the system has no partial-completion recovery path.

- 🔲 43.5 — `otherness-config-template.yaml`: add `session_budget_minutes` field — `maqa.session_budget_minutes` defaults to 90 (matching typical GitHub Actions job duration ÷ expected items per session). Projects with faster implementations can set lower values; projects with large codebases may need higher values. The field must be documented in `otherness-config-template.yaml` alongside `session_item_limit`. Without the configuration point, the budget check in 43.1 uses a hard-coded value that may be wrong for all projects except the reference project it was calibrated against. The budget is a per-project parameter, not a global constant. ⚠️ Inferred from reliability lens: the session budget varies by project; a hard-coded timeout produces false positives on fast projects and fails to trigger on slow ones.

- 🔲 43.6 — `scripts/validate.sh`: add check for `SESSION_START_EPOCH` usage in `standalone.md` — the budget watchdog (43.1) requires `SESSION_START_EPOCH` to be set at loop entry. `validate.sh` must verify that `standalone.md` contains both `SESSION_START_EPOCH` assignment (in the STARTUP or THE LOOP entry section) and a budget-check reference in the phase-boundary logic. If either is absent, validate.sh must emit: `FAIL: standalone.md missing SESSION_START_EPOCH budget tracking (required by design doc 43)`. This converts the watchdog spec from a design doc obligation to a verifiable structural requirement — the same way validate.sh enforces MODE blocks and self-update presence. ⚠️ Inferred from reliability lens: without a validate.sh check, the budget watchdog can be silently omitted from standalone.md updates and the gap will not be detected until a stalled session exposes it at runtime.

---

## Zone 1 — Obligations

**O1 — SM phase always runs, even in partial sessions.**
The SM state write is the external artifact that confirms a session ran. It must
execute regardless of what happened in COORD/ENG/QA. Budget exhaustion or startup
failure is not a reason to skip SM.

**O2 — Every silent session posts a diagnosis comment on the report issue.**
The operator must see, in the report issue, which sub-type of silent session occurred
and what the recommended next action is. A silent session with no comment is worse
than a failed session with a clear error.

**O3 — The stale watchdog does not discard commits.**
When resetting a stale `assigned` item, the watchdog must check for existing commits
before deciding whether to re-assign to QA or reset to `todo`.

---

## Zone 2 — Implementer's judgment

- `SESSION_START_EPOCH=$(date +%s)` at loop entry; budget check: `[ $(( $(date +%s) - SESSION_START_EPOCH )) -gt $(( BUDGET * 60 * 80 / 100 )) ]`
- The `prs_merged_this_session` counter: SM writes this to state.json; STARTUP reads it at session start as `0`; COORD/QA increment it on each successful merge. A simple integer in state.json, not a computed field.
- Partial completion detection: `git log --oneline origin/main..feat/$ISSUE_NUM 2>/dev/null | wc -l` returns 0 if no new commits exist, >0 if ENG made progress.

---

## Zone 3 — Scoped out

- Multi-session budget pooling (items that span multiple sessions)
- Automatic session extension (GitHub Actions does not support this)
- Cross-project session resource allocation
