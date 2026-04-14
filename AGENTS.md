# otherness — Project Agent Context

## What This Is

otherness is an autonomous software development system. A single session plays the roles of coordinator, engineer, adversarial QA, scrum master, and product manager — sequentially, in a loop, without human input. It operates on any GitHub-hosted project by reading `AGENTS.md`, `docs/aide/`, and `.otherness/state.json`, then autonomously generates work queues, implements features, reviews PRs, and ships releases.

otherness is now running on itself. When this agent improves otherness, those improvements deploy to all projects using otherness on their next run via the self-update mechanism (`git -C ~/.otherness pull`).

**Status**: Active. Core loop stable. Self-improvement mode enabled.

**⚠️ GLOBAL DEPLOYMENT WARNING — READ BEFORE EVERY MERGE**
Changes to `agents/standalone.md` or `agents/bounded-standalone.md` deploy immediately to every project using otherness worldwide on their next session startup. These files are the highest-risk change surface. See §Change Risk Tiers below.

---

## SDLC Process

The team process is embedded in `~/.otherness/agents/standalone.md`. This file contains only project-specific context.

---

## Project Config

```yaml
PROJECT_NAME:   otherness
CLI_BINARY:     ""
PR_LABEL:       otherness
REPORT_ISSUE:   1
REPORT_URL:     https://github.com/pnz1990/otherness/issues/1
BOARD_URL:      ""
BUILD_COMMAND:  bash scripts/validate.sh
TEST_COMMAND:   bash scripts/test.sh
LINT_COMMAND:   bash scripts/lint.sh
VULN_COMMAND:   ""
```

---

## Architecture

otherness is a collection of **markdown instruction files** read by OpenCode (the AI coding agent runtime). There is no compiled binary, no server, no database. The "product" is the quality of the autonomous agent loop those instructions produce.

**Deployment model**: `~/.otherness/agents/` is a git repo. Every agent self-updates via `git -C ~/.otherness pull` on startup. A merged PR to `pnz1990/otherness:main` deploys to all users on their next run.

**Runtime dependencies**: OpenCode (executes the agents), `gh` CLI (all GitHub interaction), `git` (VCS + worktree isolation + self-update), `python3` stdlib (YAML parsing, JSON state).

**State**: `.otherness/state.json` on a dedicated `_state` branch. Never on `main`. Parallel sessions use branch-push as a distributed lock.

**Skills**: `agents/skills/*.md` — reusable checklists loaded by the engineer and QA phases. Grown by `/otherness.learn`.

## Package Layout

```
~/.otherness/                  ← the repo root (git clone at this path)
  agents/
    standalone.md              ← full autonomous team loop (646 lines)
    bounded-standalone.md      ← scoped concurrent agent
    onboard.md                 ← existing project onboarding
    otherness.learn.md         ← learning agent — internalize from open-source
    gh-features.md             ← GitHub API reference
    skills/                    ← reusable skill files
      declaring-designs.md     ← spec quality standard
      reconciling-implementations.md  ← QA checklist
      agent-coding-discipline.md      ← surgical changes, verifiable goals
      autonomous-workflow-patterns.md ← workflow design patterns
      PROVENANCE.md            ← learning session audit trail
  boundaries/
    README.md
    example.boundary
  docs/
    aide/
      vision.md
      roadmap.md
      definition-of-done.md
      progress.md
  .otherness/
    state.json                 ← on _state branch only
  .opencode/
    command/
      otherness.run.md
      otherness.run.bounded.md
      otherness.setup.md
      otherness.status.md
      otherness.upgrade.md
      otherness.learn.md
  otherness-config.yaml
  otherness-config-template.yaml
  AGENTS.md
  README.md
  onboarding-new-project.md
  onboarding-existing-project.md
  scripts/
    validate.sh                ← BUILD_COMMAND target
    test.sh                    ← TEST_COMMAND target
    lint.sh                    ← LINT_COMMAND target
```

---

## Change Risk Tiers

This is the most important section. Every PR must be classified before merge.

| Tier | Files | Risk | Merge gate |
|---|---|---|---|
| **CRITICAL** | `agents/standalone.md`, `agents/bounded-standalone.md` | Deploys to ALL projects immediately. A broken instruction can stall every otherness user's next session. | **[NEEDS HUMAN] review required before merge. No autonomous merge.** |
| **HIGH** | `agents/onboard.md`, `agents/otherness.learn.md`, `otherness-config-template.yaml`, `onboarding-*.md` | Affects new project setup or the learning loop. Regressions affect onboarding experience. | QA must verify against a real project (alibi). Autonomous merge permitted if tests pass. |
| **MEDIUM** | `agents/skills/*.md`, `agents/gh-features.md`, `boundaries/` | Additive knowledge. Regressions are low-impact (agent ignores bad skill content gracefully). | Standard QA cycle. Autonomous merge. |
| **LOW** | `docs/`, `README.md`, `AGENTS.md`, `scripts/` | Documentation and scaffolding. No runtime impact. | Autonomous merge. |

**CRITICAL tier rule**: Any PR touching `agents/standalone.md` or `agents/bounded-standalone.md` must post `[NEEDS HUMAN: critical-tier-change]` on the PR and NOT be merged autonomously. Leave it for human review.

---

## What "Tests" Mean for otherness

otherness has no unit tests. Its correctness can only be validated by running it on a real project and observing behavior. The `scripts/test.sh` does the following:

1. **Markdown lint** — all `.md` files in `agents/` are well-formed.
2. **State schema check** — `agents/standalone.md` references all required state.json fields.
3. **Self-reference check** — `standalone.md` references `AGENTS.md`, `otherness-config.yaml`, and `docs/aide/` correctly (no hardcoded project paths).
4. **Skills consistency** — every skill referenced in `standalone.md` (`Load skill: read ...`) exists on disk.
5. **Integration test** — verify otherness is running correctly on the reference project (`pnz1990/alibi`) by checking the alibi `_state` branch shows activity within the last 72 hours.

`scripts/validate.sh` (BUILD_COMMAND) runs 1–4 only. `scripts/test.sh` runs all 5. `scripts/lint.sh` runs markdownlint on all agent files.

---

## The Self-Improvement Loop

When otherness runs on itself, the improvement areas are:

1. **Agent loop quality** — does the standalone agent make better decisions? Measure: fewer `[NEEDS HUMAN]` escalations per batch on reference projects, shorter time-to-merge per item.
2. **Skills depth** — are the skills files growing from `/otherness.learn` sessions? Measure: PROVENANCE.md entries, skill file count.
3. **Onboarding friction** — does `/otherness.onboard` produce complete, accurate `docs/aide/` files? Measure: how many manual edits are needed after onboarding.
4. **Documentation accuracy** — does `README.md` match actual behavior? Measure: PM validation journey passes.
5. **Tooling** — do `scripts/validate.sh`, `scripts/test.sh`, `scripts/lint.sh` catch real regressions? Measure: these scripts improve over time.

The PM phase must compare otherness against the community it came from (Hermes, Multica, Archon) every batch, and identify gaps worth closing.

---

## Anti-Patterns (QA blocks PRs containing these)

| Pattern | Caught by |
|---|---|
| Merging CRITICAL tier PR without `[NEEDS HUMAN]` label | QA — hard block |
| Hardcoding project-specific paths in `standalone.md` (e.g. `kardinal`, `alibi`, `pnz1990`) | QA |
| Agent instruction that blocks on missing optional file without graceful fallback | QA |
| Skill file that references tools not available in every OpenCode session | QA |
| Removing or weakening the self-update `git pull` at startup | QA — hard block |
| Changing `_state` branch write pattern without verifying parallel session safety | QA — hard block |
| Task `[x]` without implementation | QA |

---

## Label Taxonomy

| Group | Labels |
|---|---|
| Kind | `kind/enhancement`, `kind/bug`, `kind/chore`, `kind/docs` |
| Area | `area/agent-loop`, `area/skills`, `area/onboarding`, `area/tooling`, `area/docs` |
| Priority | `priority/critical`, `priority/high`, `priority/medium`, `priority/low` |
| Size | `size/xs`, `size/s`, `size/m`, `size/l`, `size/xl` |
| Risk | `risk/critical`, `risk/high`, `risk/medium`, `risk/low` |
| Type | `epic` |
| Workflow | `otherness`, `needs-human`, `blocked` |

---

## Product Validation Scenarios (PM Phase)

The PM agent validates otherness by observing it on reference projects.

### Scenario 1: alibi is alive

```bash
# Check that alibi's _state branch shows recent activity
git ls-remote https://github.com/pnz1990/alibi.git refs/heads/_state
# Must exist. Then:
gh api repos/pnz1990/alibi/branches/_state \
  --jq '.commit.commit.committer.date'
# Must be within 72 hours. If older: otherness has stalled on alibi.
```

Pass: alibi shows state commits within 72 hours.

### Scenario 2: alibi has open PRs or recent merges

```bash
gh pr list --repo pnz1990/alibi --json number,title,state,createdAt \
  --jq '.[] | "\(.state) \(.createdAt) \(.title)"' | head -5
```

Pass: at least one PR opened or merged in the last 7 days.

### Scenario 3: skills are growing

```bash
ls ~/.otherness/agents/skills/ | wc -l
# Must be ≥ 4 (the 4 we started with). Growing means /otherness.learn ran.
tail -20 ~/.otherness/agents/skills/PROVENANCE.md
```

Pass: PROVENANCE.md has at least one entry dated within the last 30 days.

### Scenario 4: README matches actual behavior

Read `README.md` and cross-reference against `agents/standalone.md`.
Check: every command listed in README exists in `.opencode/command/`. 
Check: every agent file listed in the stack diagram exists on disk.
Open `kind/docs` issue for each discrepancy found.

### Scenario 5: self-improvement is happening

```bash
gh pr list --repo pnz1990/otherness --state merged \
  --json mergedAt,title --jq '.[] | "\(.mergedAt) \(.title)"' | head -10
```

Pass: at least one PR merged in the last 14 days. If zero: otherness has not improved itself recently. Investigate why and open an issue.

---

## Files Agents Must Not Modify

- `AGENTS.md` (this file)
- `docs/aide/vision.md`
- `docs/aide/roadmap.md`
- `otherness-config-template.yaml` (change risk tier HIGH — QA only, not autonomous)

## Future Risk: Global Deployment Model

**Document for future consideration (Option B):**

Currently, any merged PR to `pnz1990/otherness:main` deploys immediately to every project using otherness via `git -C ~/.otherness pull`. This is Option A — fast, simple, no versioning overhead.

The risk: a bug in `agents/standalone.md` breaks every otherness session everywhere simultaneously. Currently mitigated by: CRITICAL tier requiring human review, integration test on alibi, and the fact that the agent loop is resilient (a bad instruction causes a `[NEEDS HUMAN]` rather than a crash).

When to upgrade to Option B (versioned releases):
- When otherness is used by >10 distinct repos
- When a CRITICAL tier regression has caused real damage to a non-test project
- When users need stability guarantees across sessions

Option B design: git tags as releases, projects pin to a tag in `otherness-config.yaml`, `/otherness.upgrade` bumps the pin with a changelog review step. The `git pull` self-update becomes `git checkout <pinned-tag>`.
