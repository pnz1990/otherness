# Spec: Concurrent session detection and deduplication guard

**Issue**: #712

## Design reference

- **Design doc**: `docs/design/15-multi-session-spatial-coordination.md`
- **Section**: `§ Future`
- **Implements**: Concurrent session detection and deduplication guard (🔲 → ✅)

---

## Intent

If two sessions start within the same cron window, both read identical `state.json`
before either writes heartbeat → both try to claim the same item. Branch-lock catches
this but wastes time. COORD §1b should add a lightweight guard.

---

## Zone 1 — Obligations

**O1** — `coord.md §1a` (after heartbeat write, before queue-gen) adds a concurrent-session
check: read `session_heartbeats` from `_state:state.json`. Count sessions with heartbeat
<2 minutes old (other than current session). If ≥1 concurrent session detected AND heartbeat
is <2 minutes old: log a warning and sleep 30 seconds to stagger, then continue.

**O2** — The guard is advisory only — not a hard block. After the 30s sleep, proceed
regardless. The branch-lock still catches actual collisions.

**O3** — Fail-open: if state.json read fails, skip the guard silently.

**O4** — Design doc `docs/design/15-multi-session-spatial-coordination.md` has item flipped 🔲 → ✅.

---

## Tasks

- [AI] Add concurrent session check to coord.md §1a (after heartbeat, before queue check)
- [CMD] Flip design doc item 🔲 → ✅
- [CMD] Run validate.sh + lint.sh
