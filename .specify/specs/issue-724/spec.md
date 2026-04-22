# Spec: issue-724 — 38.3 qa.md §3a CI fix loop

## Design reference
- **Design doc**: `docs/design/38-qa-ci-gate.md`
- **Section**: `§ Future → 38.3`
- **Implements**: 38.3 — `qa.md §3a`: make the CI fix path executable

## Problem statement

`qa.md §3a` currently reads CI failure logs but then has an `[AI-STEP]` comment
that says "Analyse `$_FAIL_LOG`, identify root cause, fix in `$MY_WORKTREE`."
This means the fix path is aspirational rather than executable. When CI is red, the
agent reads the log, prints it, then falls through to `sleep 30; continue` without
actually attempting a fix. Real CI failures go unresolved until 3 attempts pass and
`[NEEDS HUMAN]` is posted — even when the fix is mechanical and deterministic.

Design doc 38 §O3: "A failing CI check returns to ENG, not to `[NEEDS HUMAN]`."

## Zone 1 — Obligations (from design doc 38)

- **O1** — CI gate fires before every merge path
- **O2** — `gh pr checks` is the authoritative source
- **O3** — A failing CI check returns to ENG, not `[NEEDS HUMAN]` (this issue)
- **O4** — DCO is treated as a mechanical fix, not a CI failure
- **O5** — Gate applies on session branch PRs too

## What this spec adds (38.3 only)

Replace the `[AI-STEP]` comment block in `qa.md §3a` with a real fix loop that:

1. Parses `_FAIL_LOG` for known pattern keywords
2. For each known pattern: runs the deterministic fix command
3. Commits the fix with a short message and pushes
4. Loops back to recheck CI (the outer loop already handles this via `continue`)
5. After 3 failed fix attempts: posts `[NEEDS HUMAN]` with the failure log

### Known patterns to handle (deterministic)

| Pattern in log | Fix action |
|---|---|
| `not properly formatted` / `gofmt` | `gofmt -w .` in worktree |
| `CRLF` / `line ending` | `sed -i 's/\r//' <files>` |
| `validate.sh` fail | re-read failure and skip (already handled by outer loop) |
| `scripts/lint.sh` / `lint` error | re-run lint, fix simple issues |
| `scripts/validate.sh` hardcoded path | fix the path |
| No known pattern | Skip auto-fix — post detailed log comment, loop to NEEDS HUMAN |

For the otherness repo specifically:
- `validate.sh` fails: read actual error, attempt targeted fix
- `lint.sh` fails: check CRLF / null bytes (specific to otherness lint)

### What this does NOT handle (scoped out per design doc 38 §Zone 3)
- External infra failures (runner timeout, network error) → treated as unknown, NEEDS HUMAN
- Per-project custom CI (each project varies too much for deterministic patterns)

## Zone 2 — Implementer's judgment

- The fix loop must not loop infinitely. The outer `_CI_ATTEMPTS` counter already caps at 3.
- After posting a fix commit, push with `--force-with-lease` (same as DCO fix).
- `[AI-STEP]` comments guide the agent at runtime — they are NOT removed by this change.
  This implementation ADDS deterministic shell code that runs first; if no pattern matches,
  the `[AI-STEP]` comment still documents what intelligent fallback to apply.
- The `[AI-STEP]` comment becomes: `# [AI-STEP] If none of the above patterns matched:
  # read the full failure log, identify root cause, apply a targeted fix manually.`

## Implementation plan

1. Read current `~/.otherness/agents/phases/qa.md` §3a fix block (lines ~107-120)
2. Replace the `[AI-STEP]` block with a pattern-matching shell block
3. Run `bash scripts/validate.sh && bash scripts/lint.sh` to verify
4. Update design doc: flip 38.3 from 🔲 to ✅ in `docs/design/38-qa-ci-gate.md`
5. Commit on `feat/issue-724` branch

## Acceptance criteria

- `scripts/validate.sh` passes (no hardcoded paths, required files present)
- `scripts/lint.sh` passes (no CRLF, no null bytes, required phase headers present)
- The `[AI-STEP]` comment for the fix path is either replaced or clearly demoted to a fallback note
- Design doc 38 `§ Present` has a new ✅ 38.3 entry
