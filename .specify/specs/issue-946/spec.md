# Spec: issue-946

## Design reference
- **Design doc**: `docs/design/40-autonomous-releases.md`
- **Section**: `§ Future`
- **Implements**: 40.4 — PM §5q: release notes template with Upgrading section

---

## Zone 1 — Obligations (falsifiable)

**O1**: `agents/phases/pm.md` §5q release notes include an "Upgrading" section extracted from AGENTS.md breaking changes (if any are listed in the document).
- Verify: `grep -q 'Upgrading\|upgrading.*section\|AGENTS.md.*breaking' agents/phases/pm.md` (in §5q)

**O2**: The curated notes format is: curated summary first, then a separator, then `--generate-notes` output (hybrid). The `--notes` flag is replaced with body that includes curated summary prefix.
- Verify: `grep -q 'generate-notes\|--notes-from-tag\|--notes' agents/phases/pm.md` (hybrid pattern exists)

**O3**: `docs/design/40-autonomous-releases.md` has `40.4` moved from `🔲 Future` to `✅ Present`.
- Verify: `grep -q '✅ 40.4' docs/design/40-autonomous-releases.md`

---

## Zone 2 — Implementer's judgment

- `gh release create` doesn't support combining `--notes` with `--generate-notes`. Use `--notes-start-tag <last_tag>` + `--generate-notes` for the base, and prepend curated header via a separate notes file approach. Actually: use `--notes-file` with content that includes curated summary followed by "## Full changes\n" then fall back to just `--notes curated_notes`. The full `--generate-notes` text isn't fetched before create.
- Practical approach: prepend "## Upgrading\n" to the curated_notes if AGENTS.md has breaking change markers. If no breaking changes: section is omitted.
- "Breaking changes in AGENTS.md" = lines matching `breaking change|breaking.*behavior|removed|deprecated` in the Anti-Patterns or Future Risk sections.
- This is a modification to the existing `§5q` section, not a new section.

---

## Zone 3 — Scoped out

- Fetching the actual `--generate-notes` generated text (not accessible before release create)
- Full manual changelog curation — the curated area-grouped summary from §5q is sufficient
- Patch release (§5o) notes template — that uses --generate-notes only; 40.4 applies to minor releases
