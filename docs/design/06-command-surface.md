# 06: Command Surface — The Human-Facing Interface of otherness

> Status: Active | Created: 2026-04-17
> Applies to: all projects managed by otherness

---

## What this does

Defines what otherness commands are for, who they are for, the taxonomy of command
types, and the criteria for including, updating, or deprecating a command. The audit
of the existing command set follows from this definition — not the other way around.

Without this design doc, the command surface grows by accretion: each new capability
adds a command, nothing is ever retired, and the interface becomes a historical
artifact of the order things were built rather than a coherent surface designed for
the human who needs to use it.

---

## The D4 model for commands

In D4, the human's role is:
1. **Shape the vision** — `/otherness.vibe-vision`
2. **Start the work** — `/otherness.run`
3. **Handle escalations** — respond to `[NEEDS HUMAN]` issues
4. **Observe progress** — `/otherness.status`

Everything else is either setup (run once), maintenance (run rarely), or internal
tooling that the agent uses on itself. The command surface should reflect this
hierarchy explicitly.

### The three command types

**TYPE 1 — PRIMARY (human uses in the normal flow)**
These are the commands a human uses regularly during a project. They map directly
to the human's role in D4. Every project should have all of them. They must be
self-explanatory and well-documented.

**TYPE 2 — SETUP / MAINTENANCE (run once or rarely)**
These support project bootstrapping, agent version management, and learning. A human
runs them at project inception or during occasional maintenance windows. They are not
part of the daily loop.

**TYPE 3 — INTERNAL TOOLING (agent uses these; human can too)**
These are commands that otherness uses on itself — the arch-audit, the cross-agent
monitor, the learn session. A human can run them but they are not required for normal
operation. They should be documented as internal/advanced.

---

## Present (✅)

- ✅ Command surface audit — all 10 commands measured against taxonomy; verdicts documented in §Audit findings (PR #220, 2026-04-17)
- ✅ Deprecate `otherness.cross-agent-monitor.md` — command deleted; validate.sh updated (PR #220, 2026-04-17)
- ✅ Update `otherness.status.md` — reads _state branch before local file (this PR, 2026-04-17)
- ✅ Update `otherness.setup.md` — removed stale .maqa migration; added D4 artifact stubs (this PR, 2026-04-17)
- ✅ Update `otherness.upgrade.md` — derives otherness repo from git remote; no hardcoded slug (PR #221, 2026-04-17)
- ✅ Update README command table — PRIMARY/SETUP/INTERNAL taxonomy; vibe-vision first; cross-agent-monitor removed (PR #209, 2026-04-17)

## Future (🔲)

- 🔲 Update README command table — reflect canonical type taxonomy (PRIMARY / SETUP / INTERNAL),
  cross-agent-monitor from primary command list, add vibe-vision as the first entry
- 🔲 `otherness.setup.md` — add D4 artifact initialization: create docs/aide/vision.md
  stub, docs/aide/roadmap.md stub during setup so the project starts in D4 mode

---

## Zone 1 — Obligations

**O1 — Every command has a declared type.**
Each command's frontmatter must include its type: PRIMARY, SETUP, or INTERNAL.
This is how new contributors understand what they're looking at.

**O2 — PRIMARY commands map to the human's D4 role.**
There must be exactly one primary command per human D4 action:
- Shape vision → `/otherness.vibe-vision`
- Run the team → `/otherness.run` (+ `/otherness.run.bounded` for concurrent scoped agents)
- Observe progress → `/otherness.status`
Any additional PRIMARY commands require a design doc Future item justifying the addition.

**O3 — SETUP commands run without a fully initialized project.**
Setup commands must work in a fresh repo with no `otherness-config.yaml`, no
`docs/aide/`, and no `_state` branch. They are the bootstrap path. They must create
the D4 artifacts that PRIMARY commands depend on.

**O4 — INTERNAL commands are labeled as such.**
Commands that exist primarily for agent self-improvement (arch-audit, learn) must be
clearly labeled as advanced/internal so new users don't confuse them with the primary
loop.

**O5 — Deprecated commands are removed, not hidden.**
A deprecated command is deleted from `.opencode/command/`. It is not renamed or
moved. If a deprecated command's functionality was absorbed by another command, the
absorbing command's description is updated to say so. Kept-but-unused commands create
interface confusion.

**O6 — Commands deploy automatically via `/otherness.setup`.**
When `/otherness.setup` runs `cp ~/.otherness/.opencode/command/otherness.*.md`, all
commands — including new ones — deploy to every project. There is no opt-in or
opt-out per command. If a command should not auto-deploy, it should not be in this
directory.

---

## Zone 2 — Implementer's judgment

- Whether `otherness.run.bounded` is PRIMARY or SETUP: PRIMARY — it is a valid
  alternative to `otherness.run` for multi-agent setups. It is not required for simple
  projects, but it belongs in the primary slot because it is used regularly, not rarely.
- Whether `otherness.learn` is INTERNAL or SETUP: INTERNAL — it runs on the otherness
  repo itself, not on target projects. Target project users are unlikely to run it.
- Whether `otherness.onboard` is SETUP or PRIMARY: SETUP — it is a one-time bootstrap
  for existing projects. Once run, it is not run again.
- When to add a description field `type:` to command frontmatter vs. document in README
  only: README is sufficient for now. The `type:` frontmatter field can be added when
  commands are machine-parsed for documentation generation.

---

## Zone 3 — Scoped out

- Per-project command customization (overriding a command for a specific project) —
  the command surface is uniform across all projects. Customization is done through
  `otherness-config.yaml` parameters, not command file replacement.
- Command versioning (keeping old versions of commands) — the self-update mechanism
  deploys the latest version on every startup. There is no command-level pinning.
- Interactive command menus — commands are slash commands; they take arguments but
  do not present interactive menus.

---

## The canonical command set

### PRIMARY — used in the regular human loop

| Command | What it does |
|---|---|
| `/otherness.vibe-vision` | Shape what the product becomes — conversational vision authoring |
| `/otherness.run` | Start the autonomous team — full loop |
| `/otherness.run.bounded` | Start a scope-constrained agent — for concurrent multi-agent setups |
| `/otherness.status` | Observe — what's in flight, what's blocked, CI state |

### SETUP / MAINTENANCE — run once or rarely

| Command | What it does |
|---|---|
| `/otherness.setup` | Bootstrap a new project — config, commands, _state branch, D4 stubs |
| `/otherness.onboard` | Bootstrap an existing project — read codebase, generate docs/aide/ |
| `/otherness.upgrade` | Manage agent version pinning |

### INTERNAL / ADVANCED — agent self-improvement

| Command | What it does |
|---|---|
| `/otherness.arch-audit` | Adversarial audit — docs vs source, four-lens analysis |
| `/otherness.learn` | Study open-source repos, internalize patterns into skills |

### DEPRECATED

| Command | Verdict | Absorbed by |
|---|---|---|
| `/otherness.cross-agent-monitor` | DEPRECATE | `/otherness.status --fleet` covers the same ground |

---

## Audit findings (2026-04-17)

Each existing command measured against the taxonomy and obligations above.

### `/otherness.vibe-vision` — KEEP (new, correct)
Type: PRIMARY. Correctly placed. Frontmatter description is accurate. Agent file
exists. COORD will pick up Future items. No issues.

### `/otherness.run` — KEEP
Type: PRIMARY. Core command. Works correctly. Description accurate.

### `/otherness.run.bounded` — KEEP, minor update
Type: PRIMARY. Correct placement. The description claims "each creates its own GitHub
progress issue" — this is the false hourly-update claim removed from README. The
description should be updated to remove the "progress issue" reference since bounded
sessions don't create one automatically.

### `/otherness.status` — KEEP, update needed
Type: PRIMARY. Description accurate. **Bug**: reads from local `.otherness/state.json`
which may be stale or empty (as observed this session — state.json was 0 bytes). Should
read from `_state` branch first (same as standalone.md startup), fall back to local.

### `/otherness.setup` — KEEP, update needed
Type: SETUP. Correct placement. **Two issues**:
1. Step 4b (`.maqa/` → `.otherness/` migration) is stale — `.maqa/` was a previous
   name from an even older version. No project should have `.maqa/` today. This step
   is dead code.
2. Does not initialize D4 artifacts (`docs/aide/vision.md`, `docs/aide/roadmap.md`
   stubs). A freshly setup project has no vision.md — the human must create it before
   `/otherness.run` has anything to read. Setup should create stubs.

### `/otherness.onboard` — KEEP
Type: SETUP. Correct placement. Reads existing codebase and generates `docs/aide/`
drafts. This is the correct path for existing projects. No issues.

### `/otherness.upgrade` — KEEP, update needed
Type: SETUP/MAINTENANCE. **Bug**: hardcodes `pnz1990/otherness` as the release repo
in Step 2 and Step 3. Users who fork otherness (which the README encourages for
customization) would see releases from the wrong repo. Should derive the releases URL
from `git -C ~/.otherness remote get-url origin`.

### `/otherness.arch-audit` — KEEP
Type: INTERNAL. Correct placement. Works as demonstrated this session.
Description accurate. No issues.

### `/otherness.learn` — KEEP
Type: INTERNAL. Correct placement. No issues.

### `/otherness.cross-agent-monitor` — DEPRECATE
Type: was PRIMARY, now REDUNDANT. `/otherness.status --fleet` renders this command
unnecessary. The fleet health table in status.md (Step 4) covers the same data:
_state freshness, CI status, open PRs, needs-human count, TODO count. Running a
separate command for this creates interface confusion ("should I use status --fleet
or cross-agent-monitor?"). The answer should always be status --fleet.
