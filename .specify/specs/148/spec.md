# Spec: docs(design): populate 🔲 Future sections in design docs

> Item: 148 | Risk: low | Size: s

## Design reference
- **Design doc**: `docs/design/01-declarative-design-driven-development.md`
- **Section**: `§ Interfaces → Machine-readable Present/Future markers`
- **Implements**: adding real `🔲 Future` items to both design docs so COORD queue generator can read them (O4 compliance)

---

## Zone 1 — Obligations

**O1**: Both `docs/design/01-declarative-design-driven-development.md` and `docs/design/02-human-instruction-interpretation.md` must have parseable `## Present (✅)` and `## Future (🔲)` sections after this PR merges.
- **Falsified by**: COORD queue generator finds 0 `🔲 Future` items in docs/design/ after this PR.

**O2**: Each `🔲 Future` item in both design docs must represent real, actionable future work — not template placeholders.
- **Falsified by**: Any `🔲 Future` item contains template text like `<item description>` or `<why deferred>`.

**O3**: The `## Present (✅)` sections must accurately list what is currently implemented and shipped.
- **Falsified by**: A feature that is shipped is listed as `🔲 Future`, or a feature that is NOT shipped is listed as `✅ Present`.

**O4**: After this PR, the COORD queue generator must produce at least 1 actionable queue item from design docs (not fall back to roadmap).
- **Falsified by**: Running the queue generation script returns `SOURCE: roadmap` after this PR.

---

## Zone 2 — Implementer's judgment

- Number of `🔲 Future` items per doc: 2-4 is appropriate. More than 5 is too speculative.
- Which future items to include: drawn from Zone 3 (deferred items), future-ideas.md where applicable, and known enforcement gaps.
- Exact wording of Present/Future items is up to engineer.

---

## Zone 3 — Scoped out

- Does NOT implement any of the Future items (just declares them).
- Does NOT change any agent instruction files (agents/*, .opencode/*).
- Does NOT add new roadmap stages.
