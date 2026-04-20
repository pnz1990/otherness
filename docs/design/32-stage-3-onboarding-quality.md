# 32: Stage 3 — Onboarding Quality

> Status: Complete | Created: 2026-04-20

---

## What this does

Makes `/otherness.onboard` reliably produce a complete `docs/aide/` set for any
standard project without requiring manual editing. The acceptance criterion is:
after running `/otherness.onboard`, `/otherness.run` starts autonomously without
any human corrections to the generated files.

---

## Present (✅)

- ✅ `/otherness.onboard` command deployed — `agents/onboard.md` + `.opencode/command/otherness.onboard.md` (2026-04-14)
- ✅ `onboarding-existing-project.md` — step-by-step guide for new users (2026-04-14)
- ✅ `onboarding-new-project.md` — AGENTS.md template with D4 enforcement, anchor section, standard structure (2026-04-18)
- ✅ `otherness-config-template.yaml` — complete template with all fields: maqa, anchor, hygiene, simulation, schedule (2026-04-20)
- ✅ `agents/onboard.md` D4 enforcement — onboard runs in READ-ONLY + VISION mode for docs/, CODE zone read-only (PR #268, 2026-04-18)
- ✅ Acceptance test: `scripts/check-onboarding.sh` — structural validator for onboarding output; checks docs/aide/ required files, section headers, AGENTS.md fields, otherness-config.yaml sections (2026-04-20)
- ✅ Gap fix cycle: definition-of-done.md journey ordering fixed (Journey 7/8 were swapped), check-onboarding.sh validates 0 errors (2026-04-20)

## Future (🔲)

- 🔲 End-to-end onboarding smoke test on a live fresh repo: `scripts/check-onboarding.sh` validates structural completeness of generated docs but does NOT verify that `/otherness.run` actually starts cleanly after onboarding. Stage 3 declared complete based on structural checks only. The true acceptance test — run `/otherness.onboard` on a repo that has never seen otherness, then run `/otherness.run` and confirm the first batch ships ≥1 meaningful PR with zero `[NEEDS HUMAN]` posts — has not been performed. This test must be run and any gaps found in `agents/onboard.md` must be fixed before Stage 3 can be considered genuinely complete. ⚠️ Inferred from onboarding lens: new project added today would still require significant human intervention to get running.
- 🔲 `onboarding-existing-project.md` first-run smoke test section: the onboarding guides for existing projects are missing a "verify the loop is working" section that a human can run in <5 minutes after setup to confirm: (1) `_state` branch updated in last 24h, (2) at least one PR opened or merged in last 7 days, (3) no `[NEEDS HUMAN]` issues older than 48h. Without this, a human completing onboarding has no clear signal that it worked. `/otherness.status` should serve this purpose but its output is not yet actionable enough. ⚠️ Inferred from onboarding lens: setup guide is incomplete for first-run confidence.

---

## Zone 1 — Obligations

**O1 — `/otherness.onboard` generates all required `docs/aide/` files.**
Required: `vision.md`, `roadmap.md`, `definition-of-done.md`. Optional: `progress.md`, `metrics.md`.

**O2 — Generated files are accurate enough to start `/otherness.run` without edits.**
The measure: no `[NEEDS HUMAN]` issues in the first batch after onboarding due to missing
or wrong `docs/aide/` content.

**O3 — `AGENTS.md` template is complete.**
Every required field in the template is populated with accurate project info.

---

## Zone 2 — Implementer's judgment

- Acceptance test should use a fresh public GitHub repo with ≥100 commits of diverse code.
- Gap fix priority: vision.md first (most impactful on queue quality).

---

## Zone 3 — Scoped out

- Onboarding projects without GitHub repos
- Non-English codebases
