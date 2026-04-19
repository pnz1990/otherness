# 07: D4 Enforcement — Layered Mode Gates

> Status: Active | Created: 2026-04-17
> Applies to: all projects managed by otherness

---

## What this does

Enforces the D4 contract structurally at every layer where an agent could act —
before any file is touched, before any git command runs, before any output is
produced. An agent running in the wrong mode cannot modify files in its restricted
zone. It reads the gate, stops, and redirects the human to the correct command.

**The two protected zones:**

| Zone | What it contains | Only writable by |
|---|---|---|
| CODE | Everything outside `docs/` | `otherness.run` (IMPLEMENT mode) |
| DOCS | `docs/aide/`, `docs/design/`, `docs/*.md` | `otherness.vibe-vision` (VISION mode) |

All other agents — `otherness.arch-audit`, `otherness.learn`, `otherness.status`,
`otherness.onboard`, `otherness.setup`, `otherness.upgrade` — are READ-ONLY. They
may read anything. They may not write to either zone.

---

## The enforcement layers

There are four layers, from innermost to outermost. Each is independent — a bypass
of one layer is caught by the next.

### Layer 0 — Agent MODE DECLARATION (innermost, pre-execution)

Every agent file begins with a `## MODE` block that declares exactly what the agent
is permitted to do. The agent reads this block before any other instruction and
refuses any action that violates it.

```
## MODE: READ-ONLY
This agent may not modify, create, or delete any file. If asked to implement,
fix, or change anything, respond:

  [🚫 MODE GATE] This session is read-only.
  To implement changes: run /otherness.run
  To update vision or design docs: run /otherness.vibe-vision
```

The three valid MODE declarations:

- `READ-ONLY` — no file writes anywhere
- `IMPLEMENT` — may write to CODE zone only; blocked from DOCS zone
- `VISION` — may write to DOCS zone only; blocked from CODE zone

No agent may declare `IMPLEMENT` except `standalone.md` and `bounded-standalone.md`.
No agent may declare `VISION` except `vibe-vision.md`.

### Layer 1 — AGENTS.md project guard (project-level gate)

Every project's `AGENTS.md` contains a `## D4 ENFORCEMENT` section that lists which
modes are permitted in this project and what the redirect message is. This is the
project owner's declaration of intent — it cannot be overridden by any agent.

```markdown
## D4 ENFORCEMENT

This project enforces D4. Agents may only act within their declared mode.

| Zone | Permitted by |
|---|---|
| CODE (implementation) | /otherness.run only |
| DOCS (vision/design) | /otherness.vibe-vision only |
| Everything else | READ-ONLY |

Any agent that attempts to act outside its mode must stop and print:
  [🚫 D4 GATE] <zone> writes require <command>. Current session: <mode>.
```

### Layer 2 — Pre-flight check script (runtime gate)

`scripts/guard.sh <mode> <file-path>` — any agent can call this before writing a
file. It checks the file path against zone rules and exits non-zero if the write is
not permitted for the declared mode. Non-zero exit causes the agent to stop and
redirect.

```bash
# Usage: bash scripts/guard.sh IMPLEMENT docs/design/foo.md
# Exit 1 if IMPLEMENT mode tries to write to DOCS zone
# Exit 0 if write is permitted
```

This script can be called from any bash block in any agent file. It is the machine-
checkable version of the MODE DECLARATION.

### Layer 3 — CI branch + commit check (outermost, last resort)

A CI check verifies that PRs touching CODE came from `feat/*` branches (which only
`otherness.run` creates) and that PRs touching DOCS came from `vision/*` branches
(which only `otherness.vibe-vision` creates). This catches anything that slipped
through layers 0–2.

```yaml
# .github/workflows/ci.yml addition
- name: D4 zone enforcement
  run: bash scripts/guard-ci.sh
```

`scripts/guard-ci.sh` inspects the PR's changed files and branch name:
- Files in `docs/aide/` or `docs/design/` on a non-`vision/*` branch → fail
- Files outside `docs/` on a non-`feat/*` branch → fail (with exception for
  `chore/*` branches touching only non-code files like scripts/, README, AGENTS.md)

---

## The redirect message

Every mode gate violation produces the same structure:

```
[🚫 D4 GATE] Blocked.

This session (<current-command>) is not permitted to write to the <ZONE> zone.

To modify <zone-description>:
  Run: <correct-command>

Current session mode: <READ-ONLY | IMPLEMENT | VISION>
What you tried to do: <description>
```

The message names the correct command. The human knows exactly what to do.

---

## Present (✅)

- ✅ Layer 0: `## MODE` block added to all 12 agent files; validate.sh check 6 enforces it (PR #226, 2026-04-17)
- ✅ Layer 2: `scripts/guard.sh` — pre-flight zone check, all 5 MODE/zone combinations verified (PR #223, 2026-04-17)
- ✅ Layer 3: `scripts/guard-ci.sh` + CI workflow step — blocks feat/* branches from creating new DOCS zone files, blocks vision/* branches from modifying CODE zone files; chore/* exempt; runs on every PR (PR #224, 2026-04-18)
- ✅ `validate.sh` check 6: every agent file has a `## MODE` block — already enforced since PR #226 (check was already shipping; duplicate Future entry removed)
- ✅ Layer 1: `## D4 ENFORCEMENT` section added to `onboarding-new-project.md` AGENTS.md template; `d4_enforcement: true` added to `otherness-config-template.yaml` (PR #262, 2026-04-18)
- ✅ `vibe-vision.md` hard rule: explicit session termination rule added to HARD RULES — session ends after D4 artifacts land on main, no implementation/issues/specs (PR #267, 2026-04-18)
- ✅ `otherness.onboard` mode: MODE: VISION (writes docs/aide/ + .otherness/ exception for state bootstrap; does not write agents/ or scripts/) — accurately reflects actual behavior (PR #268, 2026-04-18)

## Future (🔲)

- 🔲 CRITICAL tier split (CRITICAL-A / CRITICAL-B) — phase file PRs that add only `[AI-STEP]` comment blocks carry different risk than PRs that modify executable loop logic; split the tier so comment-only additions are CRITICAL-B (self-review + autonomous merge) while logic changes remain CRITICAL-A (needs-human). See docs/design/13-autonomous-merge-strategy.md for the full design.

---

## Zone 1 — Obligations

**O1 — Every agent file has a MODE declaration.**
No agent file may be merged without a `## MODE` block. `validate.sh` check 6 enforces
this. The block must be the first section after the frontmatter.

**O2 — IMPLEMENT is exclusive to otherness.run.**
Only `standalone.md` and `bounded-standalone.md` may declare `MODE: IMPLEMENT`.
Any other agent declaring IMPLEMENT is a validation error.

**O3 — VISION is exclusive to vibe-vision.**
Only `vibe-vision.md` may declare `MODE: VISION`. Any other agent declaring VISION
is a validation error.

**O4 — The redirect message is always actionable.**
Every mode gate violation names the correct command. "You can't do this" without
"here's what to do instead" is not acceptable output.

**O5 — guard.sh is called before every file write in agent bash blocks.**
Any `Write`, `Edit`, or `bash` block that creates or modifies a file must be preceded
by a `guard.sh` call. This is enforced by QA review on all agent file PRs.

**O6 — CI check is non-blocking for chore branches.**
Branches named `chore/*` touching only non-zone files (scripts/, README.md,
AGENTS.md, otherness-config.yaml) are exempt from zone enforcement. These are
infrastructure changes that don't belong to either zone.

---

## Zone 2 — Implementer's judgment

- Whether `docs/<feature>.md` user docs belong to the DOCS zone: yes — any file
  under `docs/` is DOCS zone. User docs are D4 artifacts, written by vibe-vision.
- Whether `.specify/` (specs) belongs to DOCS or CODE zone: CODE zone — specs are
  written by the ENG agent as part of implementation, not by vibe-vision.
- Whether `AGENTS.md` itself is DOCS zone: no — AGENTS.md is project configuration,
  not a D4 artifact. It is writable by `otherness.setup` and `otherness.onboard`
  only during project initialization.
- How guard.sh handles files that don't exist yet (new file creation): same rules
  apply. Creating a new file in `docs/design/` from an IMPLEMENT session is blocked.
- Whether the CI check applies to direct pushes to main: yes — `guard-ci.sh` runs on
  all pushes, not just PRs. Direct pushes to main that violate zone rules fail CI.

---

## Zone 3 — Scoped out

- Enforcing D4 on projects that don't use otherness — the guard only fires if
  `otherness-config.yaml` exists and has `d4_enforcement: true`
- Per-file granularity beyond zone-level (e.g. "only vibe-vision can touch vision.md
  but onboard can touch roadmap.md") — zone-level is sufficient and simpler
- Enforcement on the otherness repo itself during arch-audit or learn sessions —
  those sessions modify `agents/` and `skills/`, which are CODE zone in the context
  of the otherness project. The arch-audit and learn agents already have appropriate
  scope limits in their instructions.

---

## Design

### The MODE block format

```markdown
## MODE: READ-ONLY

This agent reads files and produces output. It does not write, edit, create, or
delete any file in any zone.

If asked to implement, fix, or change code: respond with the D4 gate redirect
and stop. Do not proceed.

Redirect:
  [🚫 D4 GATE] Blocked. This session (/<command>) is READ-ONLY.
  To implement changes:        /otherness.run
  To update vision/design:     /otherness.vibe-vision
```

```markdown
## MODE: IMPLEMENT

This agent may write to the CODE zone only.
CODE zone: all files outside `docs/` and `docs/aide/` and `docs/design/`.

Before writing any file, verify the path is not in the DOCS zone.
If a task requires writing to `docs/aide/` or `docs/design/`: stop and redirect.

Redirect:
  [🚫 D4 GATE] Blocked. docs/ writes require /otherness.vibe-vision.
  This session (/otherness.run) cannot modify vision or design docs.
  Shape the vision first, then the team will implement.
```

```markdown
## MODE: VISION

This agent may write to the DOCS zone only.
DOCS zone: `docs/aide/`, `docs/design/`, `docs/*.md`.

This agent may NOT write specs, code, scripts, or any file outside `docs/`.
This agent stops after D4 artifacts are on main. It does not open implementation
issues, does not create feat/* branches, does not merge PRs.

If asked to implement: stop and redirect.

Redirect:
  [🚫 D4 GATE] Blocked. Code changes require /otherness.run.
  This session (/otherness.vibe-vision) writes vision artifacts only.
  Your design doc is ready. The autonomous team will implement it.
```

### guard.sh

```bash
#!/bin/bash
# scripts/guard.sh <MODE> <FILE_PATH>
# Exit 0: write permitted. Exit 1: write blocked (prints redirect).

MODE="$1"
FILE="$2"

# Determine zone from file path
DOCS_ZONE=false
if echo "$FILE" | grep -qE '^docs/'; then
    DOCS_ZONE=true
fi

case "$MODE" in
  READ-ONLY)
    echo "[🚫 D4 GATE] Blocked. This session is READ-ONLY."
    echo "  To implement changes:    /otherness.run"
    echo "  To update vision/design: /otherness.vibe-vision"
    exit 1
    ;;
  IMPLEMENT)
    if [ "$DOCS_ZONE" = "true" ]; then
        echo "[🚫 D4 GATE] Blocked. docs/ writes require /otherness.vibe-vision."
        echo "  This session (/otherness.run) cannot modify vision or design docs."
        exit 1
    fi
    exit 0
    ;;
  VISION)
    if [ "$DOCS_ZONE" = "false" ]; then
        echo "[🚫 D4 GATE] Blocked. Code writes require /otherness.run."
        echo "  This session (/otherness.vibe-vision) writes vision artifacts only."
        exit 1
    fi
    exit 0
    ;;
  *)
    echo "[🚫 D4 GATE] Unknown mode: $MODE. Cannot proceed."
    exit 1
    ;;
esac
```

### guard-ci.sh

```bash
#!/bin/bash
# scripts/guard-ci.sh — called from CI on every PR
# Checks that changed files match the branch's permitted zone

BRANCH="${GITHUB_HEAD_REF:-$(git branch --show-current)}"
ERRORS=0

# Get changed files vs base branch
CHANGED=$(git diff --name-only origin/main...HEAD 2>/dev/null || \
          git diff --name-only HEAD~1 2>/dev/null)

for file in $CHANGED; do
    IN_DOCS=$(echo "$file" | grep -cE '^docs/')
    
    case "$BRANCH" in
      feat/*)
        # IMPLEMENT zone — docs/ changes not permitted
        if [ "$IN_DOCS" -gt 0 ]; then
            echo "D4 GATE: feat/* branch cannot modify $file (DOCS zone)"
            echo "  DOCS zone changes require a vision/* branch (/otherness.vibe-vision)"
            ERRORS=$((ERRORS+1))
        fi
        ;;
      vision/*)
        # VISION zone — non-docs changes not permitted
        if [ "$IN_DOCS" -eq 0 ]; then
            # Allow exceptions: AGENTS.md, otherness-config.yaml, .specify/d4/
            EXEMPT=$(echo "$file" | grep -cE '^(AGENTS\.md|otherness-config\.yaml|\.specify/d4/)')
            if [ "$EXEMPT" -eq 0 ]; then
                echo "D4 GATE: vision/* branch cannot modify $file (CODE zone)"
                echo "  CODE zone changes require a feat/* branch (/otherness.run)"
                ERRORS=$((ERRORS+1))
            fi
        fi
        ;;
      chore/*|docs/*)
        # Infrastructure — exempt from zone enforcement
        ;;
      main)
        # Direct push to main — only SM low-risk doc commits permitted
        # (metrics.md, progress.md, handoff.md)
        ALLOWED=$(echo "$file" | grep -cE '^docs/aide/(metrics|progress)\.md$')
        if [ "$ALLOWED" -eq 0 ] && [ "$IN_DOCS" -gt 0 ]; then
            echo "D4 GATE: direct push to main cannot modify $file without a vision/* branch"
            ERRORS=$((ERRORS+1))
        fi
        ;;
    esac
done

if [ "$ERRORS" -gt 0 ]; then
    echo ""
    echo "D4 enforcement failed. $ERRORS violation(s)."
    echo "Use /otherness.run for code changes, /otherness.vibe-vision for docs."
    exit 1
fi

echo "D4 zone check: passed"
exit 0
```
