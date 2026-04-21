# Spec: `/otherness.setup` and `/otherness.onboard`: deploy workflow during setup

**Issue**: #600

## Design reference

- **Design doc**: `docs/aide/roadmap.md`
- **Section**: `§ Stage 10: Scheduled Execution`
- **Implements**: `/otherness.setup` and `/otherness.onboard`: deploy workflow during project setup (roadmap deliverable)

---

## Intent

New projects using `/otherness.setup` or `/otherness.onboard` should automatically get
the `otherness-scheduled.yml` workflow deployed to `.github/workflows/`. Currently, the
setup command only tells the human "the workflow is already present" — but it isn't
deployed automatically. A human must manually copy it.

---

## Zone 1 — Obligations

**O1** — `otherness.setup.md` gains a "Step N: Deploy otherness workflow" step that
copies `~/.otherness/.github/workflows/otherness-scheduled.yml` to
`.github/workflows/otherness-scheduled.yml` if the file does not already exist.

**O2** — `agents/onboard.md` gains the same workflow deploy step (after D4 artifacts
are written and before the final smoke test).

**O3** — Both steps are idempotent: if the file already exists, skip with a message
"otherness-scheduled.yml already present — skipping."

**O4** — If `~/.otherness/.github/workflows/otherness-scheduled.yml` is not found
(e.g. fresh install), skip gracefully with a warning.

**O5** — No design doc change needed (roadmap deliverable, not a design doc item).

---

## Tasks

- [AI] Add workflow deploy step to `.opencode/command/otherness.setup.md` (LOW tier)
- [AI] Add workflow deploy step to `agents/onboard.md` (HIGH tier)
- [CMD] Run validate.sh + lint.sh
