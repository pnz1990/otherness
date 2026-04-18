# Spec: guard-ci.sh + CI workflow — Layer 3 D4 enforcement

> Item: 224 | Created: 2026-04-18 | Status: Active

## Design reference
- **Design doc**: `docs/design/07-d4-enforcement.md`
- **Section**: `Layer 3 — CI branch + commit check`
- **Implements**: 🔲 Layer 3: guard-ci.sh + CI workflow addition (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — `scripts/guard-ci.sh` exists and is executable.**
The file `scripts/guard-ci.sh` must exist in the repo. It must exit 0 (pass) or exit 1
(fail with a D4 gate message) based on changed files vs branch name.

Behavior that violates this: the file does not exist or always exits 0.

**O2 — `feat/*` branches cannot add new `docs/design/` or `docs/aide/` files.**
guard-ci.sh must detect when a feat/* branch adds new files under `docs/aide/` or
`docs/design/` and exit 1 with a D4 gate message.

Exception: modifying existing `docs/design/` files to flip `🔲 → ✅` markers is
permitted on `feat/*` branches (these are design doc updates shipped with features).
guard-ci.sh distinguishes between modifications (permitted) and new file creation
(blocked).

Behavior that violates this: a feat/* branch that creates a new `docs/design/` file
passes CI.

**O3 — `vision/*` branches cannot touch files outside `docs/`.**
guard-ci.sh must detect when a vision/* branch modifies files outside `docs/` (with
exemptions: AGENTS.md, otherness-config.yaml, `.specify/d4/`) and exit 1.

Behavior that violates this: a vision/* branch that modifies `scripts/validate.sh`
passes CI.

**O4 — `chore/*` branches are exempt from zone enforcement.**
Branches named `chore/*` are not checked. These are infrastructure changes.

Behavior that violates this: a chore/* branch that modifies README.md fails CI.

**O5 — guard-ci.sh is added as a CI step in `.github/workflows/ci.yml`.**
The CI workflow must include a step that runs `bash scripts/guard-ci.sh` on pull
request events. The step runs after checkout. It is skipped on push events (direct
main pushes are exempt from this check).

Behavior that violates this: guard-ci.sh exists but is not invoked in CI.

**O6 — guard-ci.sh prints an actionable D4 gate message on failure.**
On any violation, the script prints the violating file and branch, and names the
correct command to use instead.

Behavior that violates this: the script exits 1 silently.

**O7 — guard-ci.sh exits 0 on the otherness repo's existing feat/* PR history.**
Running guard-ci.sh against the current state of any open feat/* PR in the repo
must not generate false positives that would block legitimate PR patterns (design
doc 🔲→✅ updates, spec files in .specify/).

Behavior that violates this: guard-ci.sh blocks the very PR that implements it
(feat/224 contains docs/design/07-d4-enforcement.md modification).

---

## Zone 2 — Implementer's judgment

- How to detect "new file vs modification": use `git diff --diff-filter=A` (added) vs
  `git diff --diff-filter=M` (modified). New files in docs/aide/ or docs/design/ on
  feat/* are blocked; modifications to existing files are permitted.
- Where to get the base branch diff in CI: use `git diff --name-only origin/main...HEAD`
  (same pattern as the existing CRITICAL tier check).
- Whether to also exempt `.specify/` from feat/* restrictions: yes — `.specify/specs/`
  is CODE zone per design doc 07 Zone 2. It is never blocked.
- Whether to run on direct push to main: no — CI step uses `if: github.event_name == 'pull_request'`.
  Direct main pushes are SM low-risk doc commits and are exempt.
- Number of lines in guard-ci.sh: keep it simple and auditable — under 60 lines.

---

## Zone 3 — Scoped out

- Per-line diff analysis (checking what changed, not just whether a file was added/modified)
- Enforcement on direct pushes to main
- Enforcement on branches that don't match feat/*, vision/*, chore/* (unrecognized branch
  patterns are logged but not blocked)
- Retroactive enforcement of existing merged PRs
