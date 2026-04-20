# Spec: fix(validate): add vibe-vision-auto.md and autonomous-vision.md to required files check

## Design reference
- **Design doc**: `docs/design/27-security-model.md`
- **Section**: `§ Zone 1 — Obligations: O1 — required files present`
- **Implements**: Full required-files coverage for all agent files used in production workflows (🔲 → ✅)

---

## Problem

`scripts/validate.sh` check [3/5] (required files) does not include all agent files
that are actively used in production. Specifically:

1. `agents/vibe-vision-auto.md` — Used in Step A of `.github/workflows/otherness-scheduled.yml`
   (the dual-step scheduled workflow). Missing or broken vibe-vision-auto.md would cause
   Step A to silently fail without CI catching it during validate.

2. `agents/autonomous-vision.md` — Referenced in `docs/aide/roadmap.md` Stage 9 as a
   required deliverable and used in Stage 9 autonomous vision synthesis. Missing file
   would cause the vision synthesis trigger to fail silently.

Both files exist today. This spec adds them to the required files check to prevent
future regressions.

---

## Zone 1 — Obligations

**O1**: Add `agents/vibe-vision-auto.md` to `scripts/validate.sh` REQUIRED array.

**O2**: Add `agents/autonomous-vision.md` to `scripts/validate.sh` REQUIRED array.

**O3**: Both additions must be adjacent to the existing `agents/vibe-vision.md` entry
(currently line 151) for readability — group all vibe-vision related files together.

---

## Zone 2 — Implementer's judgment

- Where to insert: after `"$AGENTS_DIR/otherness.learn.md"` line, since these are
  agent files in the same directory. Or after the `agents/vibe-vision.md` line —
  either is acceptable.
- No new test needed — validate.sh is itself the test. The fix is the test.

---

## Zone 3 — Scoped out

- Adding `agents/cross-agent-monitor.md` to required files: this file exists in
  `~/.otherness/agents/` but is NOT a deployable command in `.opencode/command/`.
  AGENTS.md package layout has a stale entry (`otherness.cross-agent-monitor.md`
  in `.opencode/command/`). Fix is out of scope for this PR — that's a separate
  AGENTS.md documentation issue.
- Fixing AGENTS.md package layout: not in scope (AGENTS.md is protected).

---

## Implementation plan

1. Edit `scripts/validate.sh`: insert two entries in the REQUIRED array after
   the existing `"$AGENTS_DIR/vibe-vision.md"` line:
   - `"$AGENTS_DIR/vibe-vision-auto.md"`
   - `"$AGENTS_DIR/autonomous-vision.md"`

2. Run `bash scripts/validate.sh` to confirm no regression.

3. Commit, push, open PR.

**Tier**: LOW — `scripts/` only. Autonomous merge.
