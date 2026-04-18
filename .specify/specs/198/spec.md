# Spec: fix coord stale watchdog REPO→origin (#198)

## Design reference
- N/A — infrastructure bug fix with no user-visible behavior change

## Zone 1 — Obligations

**O1** — `coord.md` stale item watchdog branch-delete call uses `'origin'` as git remote, not `REPO`.

Falsifiable: `grep "git.*push.*REPO.*--delete" agents/phases/coord.md` returns zero matches after this fix.

**O2** — The queue-gen lock recovery (existing correct usage) is unchanged.

Falsifiable: `grep "git.*push.*origin.*--delete.*queue-gen" agents/phases/coord.md` still returns one match.

**O3** — No other `git push REPO` patterns exist in coord.md or other phase files for branch deletion.

Falsifiable: scan of all agents/phases/*.md for `git push.*REPO.*--delete` returns zero matches.

## Zone 2 — Implementer's judgment

- Audit all phases/*.md for the same pattern as part of this fix.

## Zone 3 — Scoped out

- Fixing the REPO variable definition (it's correct for gh CLI — only wrong for git remote ops)
- Changing gh CLI calls that correctly use the slug
