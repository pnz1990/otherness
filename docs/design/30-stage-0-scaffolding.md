# 30: Stage 0 — Scaffolding

> Status: Complete | Created: 2026-04-20

---

## What this does

Provides the minimum infrastructure for otherness to run on itself. All four
required scripts exit 0, the project has proper docs, config, and CI, and the
agent can read the project state from `_state` branch.

This stage is the bootstrap: before Stage 0 is complete, otherness cannot
autonomously improve itself.

---

## Present (✅)

- ✅ `scripts/validate.sh` — markdown structure checks: no hardcoded project paths in agents/, skill refs exist on disk, required files present, self-update block present (2026-04-14)
- ✅ `scripts/test.sh` — full test suite: validate checks + integration check against reference project `_state` branch (2026-04-14)
- ✅ `scripts/lint.sh` — structural correctness checks on agent files: CRLF, null bytes, required phase headers (2026-04-14)
- ✅ `AGENTS.md` — project context for the agent, including change risk tiers, anti-patterns, PM validation scenarios (2026-04-14)
- ✅ `otherness-config.yaml` — project config with all required fields (2026-04-14)
- ✅ `docs/aide/` — vision.md, roadmap.md, definition-of-done.md, progress.md, metrics.md (2026-04-14)
- ✅ `.opencode/command/otherness.*.md` — all command files deployed and synced from `~/.otherness` (2026-04-14)
- ✅ `_state` branch with seeded `state.json` — parallel sessions use it as distributed lock (2026-04-14)
- ✅ GitHub report issue #2 and all labels (kind/*, area/*, priority/*, size/*, risk/*, otherness, needs-human, blocked) (2026-04-14)
- ✅ CI: `.github/workflows/ci.yml` — validate + lint on every PR (2026-04-14)
- ✅ `otherness-config-template.yaml` — project config template for new projects (2026-04-17)

## Future (🔲)

*(Stage 0 is complete. All deliverables shipped. This doc exists to make Stage 0 design-doc-covered per PM roadmap health checks.)*

---

## Zone 1 — Obligations

**O1 — All four scripts exit 0 on a clean repo.**
`validate.sh`, `test.sh`, `lint.sh` must all pass before any otherness session starts
work. CI enforces this on every PR.

**O2 — Agent can read its own config on startup.**
`otherness-config.yaml` must be present and parseable. AGENTS.md must be present.
Without these, the agent cannot determine what project it is on.

**O3 — State is isolated to `_state` branch.**
`state.json` lives on `_state`, never on `main`. This prevents code PRs from
conflicting with state updates.

---

## Zone 2 — Implementer's judgment

- Script choice: bash for portability across CI environments.
- Validate checks use Python stdlib (no external tools required on runners).
- State branch uses worktree isolation for parallel-safe writes.

---

## Zone 3 — Scoped out

- Automated test for script correctness (scripts are validated structurally, not functionally)
- Rollback mechanism for state corruption (manual intervention required)
- Multi-repo setup automation (covered by Stage 0 setup scripts)
