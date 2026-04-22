# Spec: Skill load verification in ENG §2c and SM §4b

## Design reference
- **Design doc**: `docs/design/31-stage-2-skills-expansion.md`
- **Section**: `§ Future`
- **Implements**: Skill load verification — ENG must confirm which skills were loaded before implementation (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1** — ENG `§2c` must include an explicit skill-loading confirmation step that:
  (a) lists the skill files checked at session start,
  (b) selects the most applicable skill file for the current item type,
  (c) logs `Loaded skill: \`<filename>\`` in the PR description.

_Violation_: PR description does not contain a "Loaded skill:" line; or ENG §2c has no instruction to list and select skills.

**O2** — SM §4b must, once per session, check that the last 5 ENG PRs each include a
"Loaded skill:" line in their description. If fewer than 3 of 5 do:
SM §4b must open a deduplicated `kind/chore` issue:
`"Skill loading discipline has drifted — ENG is not citing skill files."`

_Violation_: SM §4b never checks PR descriptions for "Loaded skill:"; or the chore issue is opened even when ≥3 of 5 PRs include the line; or duplicate issues are opened.

**O3** — The SM §4b check must be fail-open: if `gh pr list` API call fails, or fewer than
5 merged PRs exist, the check is skipped silently without opening any issue.

_Violation_: SM §4b crashes or opens a false-alarm issue when the API is unavailable or PR count < 5.

---

## Zone 2 — Implementer's judgment

- Where exactly in ENG §2c to insert the skill-loading confirmation step (before or after the spec quality gate) is implementer's choice; before writing any code is preferred.
- Whether to list skill files via bash `ls` or a hardcoded mention is implementer's choice.
- The SM §4b check may scan PR body OR PR title for "Loaded skill:" — body is preferred.
- The chore issue title may vary slightly from the exact quoted text as long as it contains "skill loading discipline" and "ENG".

---

## Zone 3 — Scoped out

- Automatically enforcing skill loading (blocking PRs without the line) — out of scope
- Tracking per-skill citation rate across all PRs (separate design doc item)
- Automatically selecting the "best" skill file — out of scope (human/AI judgment)
