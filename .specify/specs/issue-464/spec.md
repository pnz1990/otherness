# Spec: validate.sh dual-step workflow check (issue-464)

## Design reference
- **Design doc**: `docs/design/28-dual-step-scheduled-workflow.md`
- **Section**: `§ Future`
- **Implements**: `scripts/validate.sh`: check that scheduled workflow has 2 opencode steps when `vibe_vision_step: true` (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — validate.sh exits with error when `schedule.vibe_vision_step=true` AND workflow has <2 opencode steps.**
Reads `vibe_vision_step` from `otherness-config.yaml schedule:` section. Default: true.
Counts `uses: anomalyco/opencode` lines in the workflow file. If count < 2: exit 1.

**O2 — Check only runs when `schedule.cron` is set AND workflow file exists.**
If no cron or no workflow file: skip (checked by existing guard).

**O3 — Error message is actionable.**
Tells the user: what's wrong, what to do, design doc reference.

**O4 — Default for `vibe_vision_step` is `true`.**
Per design doc O5: opt-out, not opt-in.

---

## Zone 2 — Implementer's judgment
- Count opencode steps by `uses: anomalyco/opencode` pattern (covers all SHA-pinned versions)

## Zone 3 — Scoped out
- Checking that Step A prompt is vibe-vision and Step B is run (content check, not structure)
