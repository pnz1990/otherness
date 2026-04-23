# Spec: validate.sh check for README last-modified date comment

## Design reference
- **Design doc**: `docs/design/39-autonomous-readme-refresh.md`
- **Section**: `§ Future`
- **Implements**: 39.5 — validate.sh check: README last-modified date recorded in a comment at top of README

## Zone 1 — Non-negotiable obligations

1. **O1**: Add a new check to `scripts/validate.sh` that reads `README.md` and:
   - Checks if a `<!-- last-refreshed: YYYY-MM-DD -->` comment exists in the file
   - Gets the README's last-modified date from `git log`
   - If README is >90 days old AND no `<!-- last-refreshed -->` comment exists: FAIL with clear message
   - If README has no git history (new repo): pass gracefully
   - If git is not available: pass gracefully (fail-open)
2. **O2**: Add `<!-- last-refreshed: 2026-04-21 -->` comment to the top of `README.md` (since PM §5k writes this as a placeholder per item 39.3).
3. **O3**: Mark item 39.5 as `✅ Present` in `docs/design/39-autonomous-readme-refresh.md`.

## Zone 2 — Nice to have
- Clear error message mentioning the PM §5k that writes this comment.

## Out of scope
- Changes to any agent .md phase files.
- Rewriting the README content.

## Risk tier
LOW — only `scripts/validate.sh`, `README.md`, and `docs/design/39-autonomous-readme-refresh.md` are modified.

## Verifiable goal
- `bash scripts/validate.sh` passes with "OK: README last-refreshed check passed"
- README.md contains `<!-- last-refreshed: ...`
