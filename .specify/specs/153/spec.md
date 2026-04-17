# Spec: feat(tooling): validate.sh CI lint for ## Design reference

> Item: 153 | Risk: low | Size: xs

## Design reference
- **Design doc**: `docs/design/01-declarative-design-driven-development.md`
- **Section**: `§ Future (🔲)`
- **Implements**: CI lint for `## Design reference` presence in spec files (🔲 → ✅)

---

## Zone 1 — Obligations

**O1**: `scripts/validate.sh` must include a new check that verifies every `.specify/specs/*/spec.md` file contains a `## Design reference` section.
- **Falsified by**: validate.sh exits 0 when a spec.md is missing `## Design reference`.

**O2**: The check must exit non-zero (failing validate.sh) if any spec.md lacks the section.
- **Falsified by**: validate.sh exits 0 even when a spec is missing the design reference.

**O3**: The check must be graceful when `.specify/specs/` does not exist (new projects without specs yet should not fail).
- **Falsified by**: validate.sh fails when `.specify/specs/` directory is absent.

**O4**: The check counter must be added as step 5 to validate.sh (keeping the existing step numbering consistent).
- **Falsified by**: Existing checks renumbered or removed.

**O5**: `docs/design/01-DDDD.md` `## Future` must be updated: `🔲 CI lint for ## Design reference` → `✅ Present`.
- **Falsified by**: Item still in Future after merge.

---

## Zone 2 — Implementer's judgment

- Bash pattern for finding spec files: `find .specify/specs -name "spec.md"` or glob.
- Error message should name the failing spec file.

---

## Zone 3 — Scoped out

- Does NOT check spec content quality (prose quality is not machine-checkable).
- Does NOT check `## Design reference` content, only presence.
- Does NOT modify `scripts/test.sh` or `scripts/lint.sh`.
