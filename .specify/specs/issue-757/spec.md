# Spec: COORD §1b unified startup signal reader

## Design reference
- **Design doc**: `docs/design/35-quality-of-output-gaps.md`
- **Section**: `§ Future`
- **Implements**: COORD §1b must check `housekeeping_streak` and `next_session_directive` at session start as a single unified preflight (🔲 → ✅)

---

## Zone 1 — Obligations

**O1** — COORD §1b must read the following signals from `state.json` at session startup,
before any queue generation or item claiming:
- `housekeeping_streak` (integer ≥ 0)
- `next_session_directive` (string or null)
- `frame_lock_detected` (boolean or null)
- `silent_session_count` (integer ≥ 0)
- Presence of open `needs-human` issues on GitHub
- Violation: any of these signals is consumed only in later phases (§1c, §1e) without a unified preflight read at §1b.

**O2** — The signals must be acted on in this priority order (highest first):
1. Open `needs-human` issues → log count and proceed with caution (do NOT stop)
2. `housekeeping_streak ≥ 3` → trigger vision synthesis first, skip chore claims this session
3. `next_session_directive` non-null → reorder claim priority to match directive
4. `frame_lock_detected` true → prefer learn-type items when claiming
5. (no signal) → normal operation
- Violation: conflicting signals produce unpredictable behavior because no precedence order is applied.

**O3** — The preflight must log its findings in a single consolidated message (does not
require posting to GitHub — stdout is sufficient). Format:
`[COORD §1b-preflight] needs_human=N streak=N directive=<val> frame_lock=<val> action=<one of: caution|vision-first|directive|learn-prefer|none>`
- Violation: no log message is produced, making it impossible to debug signal conflicts.

**O4** — When `housekeeping_streak ≥ 3`, the preflight must set `COORD_ACTION=vision-first`
(shell variable) so §1c knows to call vibe-vision-auto before queue-gen, not after.
- Violation: `housekeeping_streak ≥ 3` is logged but does not affect §1c behavior.

**O5** — Graceful fallback: if `state.json` is missing or malformed, the preflight
treats all signals as absent (no action). The session continues normally.
- Violation: missing or malformed state.json causes the session to crash or stall.

---

## Zone 2 — Implementer's judgment

- The preflight is a new bash+python block inserted into §1b, after the vision check
  but before §1c queue generation.
- `housekeeping_streak` is an existing field in state.json (set by SM §4b).
  If missing: treat as 0.
- `next_session_directive` and `frame_lock_detected` may not yet be written by SM.
  If missing or null: treat as inactive.
- The `COORD_ACTION` variable is consumed by the existing §1c block to decide
  whether to run vibe-vision-auto first.
- "prefer learn-type items" for frame_lock means the §1e claim sort key should
  deprioritize the current queue and prefer items with `area/skills` or containing
  "learn" in the title. Implemented as a sort key adjustment in §1e.

---

## Zone 3 — Scoped out

- Writing `housekeeping_streak` or `frame_lock_detected` — that is SM's job.
- Implementing `recovery_action` from sim-prediction.json — that field may not exist yet.
- Changing the vision check (first half of §1b) — it stays as-is.
- Cross-session signal aggregation — each session reads the latest state snapshot.
