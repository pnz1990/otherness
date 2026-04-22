# Spec: issue-897 — SM §4a speckit release check (design doc 42.3)

## Design reference
- **Design doc**: `docs/design/42-speckit-integration.md`
- **Section**: `§ Future`
- **Implements**: 42.3 — SM §4a: speckit release check (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — Every 10 SM cycles, SM queries GitHub API for the latest speckit release.**
If the API is unavailable or speckit is not installed, skip gracefully (fail-open).

**O2 — Compare against currently installed version (`specify --version 2>/dev/null`).**
If speckit is not installed, skip the check entirely.

**O3 — Open a `kind/chore` issue if the installed version is >1 minor behind AND the latest release notes contain reliability/context-parsing keywords.**
Keywords: "non-interactive", "BOM", "context", "upsert".

**O4 — Deduplication: at most one open speckit update issue at a time.**

---

## Zone 2 — Implementer's judgment

- Version comparison: `v1.2.3` parsed as (1, 2, 3). "1 minor behind" means latest_minor > installed_minor (same major).
- The GitHub API endpoint is `https://api.github.com/repos/github/spec-kit/releases/latest`. Use `gh api` not `curl` for auth.
- Release notes are in the `body` field of the releases API response.
- If speckit is not installed (`specify --version` fails): log "[SM §4a-speckit] speckit not installed — skipped." and exit.

---

## Zone 3 — Scoped out

- Auto-upgrading speckit (human decision)
- 42.1, 42.2, 42.4 (separate items)
