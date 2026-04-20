# Spec: coord.md §1c Queue-Gen Issue Creation — Make Executable

## Design reference
- **Design doc**: `docs/design/22-queue-richness.md`
- **Section**: `§ Future — coord.md §1c source priority cascade`
- **Implements**: Replace [AI-STEP] block with executable issue creation python3 (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1** — `coord.md §1c` must NOT contain the `[AI-STEP] For each ITEM line above:` comment. Violation: grep finds the comment.

**O2** — The issue creation python3 block must create up to 20 issues per queue-gen run, each with `## Design reference` body section. Violation: issues created without Design reference section.

**O3** — Duplicate suppression: `open_if_absent` uses gh issue list search before creating. Violation: creates duplicate issues for same item.

**O4** — Spatial diversity: items sorted so each design doc source appears once before repeats. Violation: first 10 issues all from same design doc.

**O5** — validate.sh and lint.sh pass. Violation: non-zero exit.

---

## Zone 2 — Implementer's judgment

- Area label derived from design doc source name (not item content) — simple and consistent.
- "feat:" prefix on issue titles for all design-doc-sourced items.

---

## Zone 3 — Scoped out

- Roadmap source fallback in issue creation (separate item)
- State JSON update with queued issue IDs (done separately in the §1c state write)
