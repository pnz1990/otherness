# Spec: command surface fixes #216 #217 #218

## Design reference
- **Design doc**: `docs/design/06-command-surface.md`
- **Implements**: UPDATE verdicts for status.md, setup.md, upgrade.md (🔲 → ✅)

## Zone 1 — Obligations

**O1** — `otherness.status.md` fetches from `origin/_state` before reading state.json.
Falsifiable: `grep "fetch origin _state" .opencode/command/otherness.status.md` → match.

**O2** — `otherness.setup.md` Step 4b (`.maqa/` migration) is removed.
Falsifiable: `grep "\.maqa" .opencode/command/otherness.setup.md` → no match.

**O3** — `otherness.setup.md` creates `docs/aide/vision.md` and `docs/aide/roadmap.md` stubs if absent.
Falsifiable: `grep "docs/aide/vision.md" .opencode/command/otherness.setup.md` → match.

**O4** — `otherness.upgrade.md` derives the otherness repo URL from git remote, not hardcoded slug.
Falsifiable: `grep "pnz1990/otherness" .opencode/command/otherness.upgrade.md` → no match
(except in comments/examples that are clearly illustrative).

## Zone 2 — Implementer's judgment
- D4 stubs in setup.md should be minimal — one or two sentences each, clearly marked for the human to fill in.
- upgrade.md hardcode appears in Step 2 and Step 3 — both must be updated.

## Zone 3 — Scoped out
- Changing the structure of setup.md beyond the two specific issues
- Changing the upgrade.md UI/UX
