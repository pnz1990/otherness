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
- 🔲 SM §4f must update `docs/aide/progress.md` every batch with accurate state: `docs/aide/progress.md` currently says "Batch 22 (2026-04-17)" — the actual batch count is now 93+. The document is a lie that a human will find and distrust. SM §4f must: (a) read the current batch count from `docs/aide/metrics.md` (count rows), (b) read the most recent health signal and last-shipped PR title from state.json, (c) rewrite the "Current State" section of `docs/aide/progress.md` with accurate batch number, date, health signal, last-shipped PR, and queue depth. This is the same gap identified in `docs/design/06-command-surface.md` — but the specific symptom (progress.md frozen at Batch 22 while reality is Batch 93) makes the priority concrete. A human looking at the repo today sees stale progress and cannot tell if the system is alive. ⚠️ Inferred from visibility lens: docs/aide/progress.md is 71 batches behind reality; the system's self-reported state is wrong.
- 🔲 `/otherness.onboard` must generate a project-specific vision pressure context: when a new project is onboarded, the scheduled workflow is created with the generic otherness pressure prompt (the one in this file). But a new project (e.g. a React dashboard app) has completely different gaps than otherness itself. The first 3–5 batches after onboarding will be driven by the otherness self-improvement pressure, not by the actual project's needs. `/otherness.onboard` must: (1) read `docs/aide/vision.md` and the project codebase, (2) synthesise a project-specific "Context for this vision scan:" block addressing the project's real gaps, (3) write it into the scheduled workflow file before committing. Without this, every new project starts with misdirected pressure and wastes its first batches on the wrong work. ⚠️ Inferred from onboarding lens: new project onboarded today would get otherness-specific pressure prompts irrelevant to its own codebase.
- 🔲 Onboarding generates `docs/design/` stubs from real codebase analysis: `/otherness.onboard` currently creates `docs/aide/` files but does NOT create `docs/design/` stubs. The result: a newly onboarded project's COORD finds no `🔲 Future` items in `docs/design/`, the queue refusal guard fires immediately, and the session falls back to autonomous vision synthesis — generating lower-quality machine-inferred items rather than human-quality design docs. `/otherness.onboard` must produce at least 3 `docs/design/` stubs with real `🔲 Future` items derived from codebase analysis, covering the most important improvement areas visible in the code. This gives the first batch a meaningful queue without requiring human authorship of design docs first. ⚠️ Inferred from onboarding lens: onboarding produces docs/aide/ but not docs/design/; first-batch queue will be machine-generated noise, not design-backed work.
- 🔲 Post-onboard project drift detection in SM: once a project is onboarded and running, there is no mechanism to detect when it has drifted — `docs/aide/` files go stale, `otherness-config.yaml` gets outdated, `vision.md` no longer describes what the project actually builds. SM must include a quarterly drift check (every 30 batches): (a) verify `docs/aide/vision.md` word count and last-commit date — if unchanged for 60+ batches, flag as stale; (b) verify that new `docs/design/` files have been added in the last 30 batches — if zero new design docs: the system is consuming backlog but not generating new direction; (c) verify `otherness-config.yaml` fields still point to valid repo, label, and issue. Each failing check opens a `kind/chore priority/low` issue with a specific remediation. A project that stops generating new design docs is almost certainly stalling, but the current system cannot detect this signal. ⚠️ Inferred from onboarding lens: a new project added today gets onboarded once but has no ongoing health check to detect when its otherness config drifts from reality.

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
