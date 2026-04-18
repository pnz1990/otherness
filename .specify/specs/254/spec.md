# Spec: Cross-check README/AGENTS.md claims against code

> Item: 254 | Created: 2026-04-18 | Status: Active

## Design reference
- **Design doc**: `docs/design/04-documentation-health.md`
- **Section**: `## Future`
- **Implements**: Cross-check README/AGENTS.md claims against code (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — PM phase §5f (or §5g) includes a README/AGENTS.md claims check.**
A new step is added to the documentation health section in `agents/phases/pm.md`:
cross-check machine-verifiable claims in README.md and AGENTS.md against the
actual state of the repo.

Behavior that violates this: the claims check is absent from pm.md.

**O2 — The check verifies file-existence claims.**
Claims in README.md and AGENTS.md that reference specific files (e.g. "scripts/validate.sh
performs N checks", "X.md exists") must be verified to still be true. Files that no
longer exist are flagged.

The check covers:
- Files listed in the Package Layout section of AGENTS.md
- Files named in README.md command table (`.opencode/command/otherness.*.md`)
- Scripts referenced in AGENTS.md project config (BUILD_COMMAND, TEST_COMMAND, LINT_COMMAND)

Behavior that violates this: the check only verifies validate.sh check counts, not
file existence.

**O3 — The check verifies validate.sh step count claim.**
AGENTS.md/README claim validate.sh performs N checks. The check counts the actual
`echo "[N/N]"` lines in scripts/validate.sh and opens a kind/docs issue if the
claimed N differs from the actual count.

Behavior that violates this: the step count is never verified.

**O4 — Issues are only opened for gaps not already open (duplicate-suppressed).**
Same `open_if_absent` pattern as §5f.

Behavior that violates this: same false-claim issue opened on every PM cycle.

**O5 — The check runs every N_PM_CYCLES cycles inside the cadence gate.**
Same cadence as §5f.

Behavior that violates this: runs every cycle or never.

---

## Zone 2 — Implementer's judgment

- Where to add: as a new §5g section in pm.md, separate from §5f (which covers design
  docs). This keeps §5f focused on design doc health and §5g focused on README/AGENTS.md.
- Scope of "machine-verifiable claims": limit to file existence checks and validate.sh
  step count. Do not try to verify prose claims (e.g. "the agent loop is stable") —
  that requires judgment and is out of scope.
- Whether to check command file existence: yes — verify that every command file listed
  in README.md command table actually exists in `.opencode/command/`.
- How to get validate.sh step count: `grep -c '^\s*echo.*\[.*/' scripts/validate.sh`
  or count `=== validate:` pattern. Compare against AGENTS.md claim.

---

## Zone 3 — Scoped out

- Prose/semantic claims in README or AGENTS.md
- Claims about agent behavior or quality ("the agent is stable")
- Claims in files other than README.md and AGENTS.md
- Retroactive fixing of existing false claims (open issues only)
