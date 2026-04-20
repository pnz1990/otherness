# Spec: Frame-lock break protocol in otherness.learn.md / SM §4c

## Design reference
- **Design doc**: `docs/design/35-quality-of-output-gaps.md`
- **Section**: `§ Future`
- **Implements**: `agents/otherness.learn.md` / `SM §4c`: frame-lock break protocol (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — SM §4c detects frame-lock: arch_convergence >= 0.65 for 3 consecutive calibrations.**
SM §4c must read the `arch_convergence_score` from the last 3 entries in the
`sim-prediction.json` git log on `_state`. If all 3 are >= 0.65, SM sets the
`frame_lock_detected` flag in state.json and posts a `learn(arch):` issue with
`frame-lock` label. Violation: frame-lock condition met but no issue opened.

**O2 — The frame-lock learn issue specifies arch-diverse target selection.**
The issue body must instruct the learn agent to choose repos from a paradigm
UNLIKE the current skills library. The issue body must include a heuristic:
current skills categories extracted from PROVENANCE.md, and a directive to
pick a repo from a DIFFERENT category. Violation: issue opened but does not
specify diversity requirement.

**O3 — `otherness.learn.md` documents the "unlike" heuristic.**
A new section `## 1b-arch-diverse: Architecture-diverse target selection (frame-lock mode)`
must be added to `otherness.learn.md`. It describes how to detect the current skill
category distribution and select a target from an underrepresented category.
Violation: section absent from learn.md.

**O4 — Frame-lock detection uses 3 consecutive calibrations, not 3 arbitrary ones.**
The 3 readings must be from the git log of `sim-prediction.json` on `_state` (most
recent 3 entries), not from state.json or metrics.md. Violation: count uses non-
consecutive or non-calibration-derived readings.

**O5 — Frame-lock flag is reset when arch_convergence drops below 0.55.**
If the flag is set and the latest arch_convergence < 0.55, SM §4c clears
`frame_lock_detected` in state.json. Violation: flag persists after convergence drops.

---

## Zone 2 — Implementer's judgment

- Arch category heuristics: scan PROVENANCE.md for source repos; classify by primary
  domain (agent-loop, data-pipeline, frontend, backend-service, devops, ml-training).
  If current skills are dominated by agent-loop (>60%), recommend data-pipeline or
  frontend. This is a heuristic — exact categories are implementer's choice.
- Where to write frame_lock_detected: in state.json top-level field (not in features dict).
- Deduplication for the learn issue: same as existing learn(arch) dedup check.
- Whether to block other learn sessions: no. The frame-lock issue is an escalated
  priority signal, not a lock.

---

## Zone 3 — Scoped out

- Automatically running /otherness.learn with arch-diverse targets (opens issue only)
- Tracking which repos were studied per category (full taxonomy tracking)
- Cross-project frame-lock propagation (each project tracks its own)
