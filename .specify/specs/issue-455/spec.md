# Spec: Feature→journey parity check in SM §4g-anchor-parity (issue-455)

## Design reference
- **Design doc**: `docs/design/26-anchor-kro-ui.md`
- **Section**: `§ Future`
- **Implements**: Feature→journey parity check: SM §4g-anchor reads AGENTS.md spec inventory (Merged rows), diffs against journey file names, opens anchor-growth issues for specs with no journey (🔲 → ✅)

## Context

Projects like kro-ui maintain a journey test suite (directory of test files, one per spec).
The §4g-anchor-parity SM section reads:
1. The merged spec inventory from AGENTS.md §Anchor (✅/[x] entries)
2. Journey file names from `anchor.journeys_dir` configured in `otherness-config.yaml`
3. Diffs them, opens anchor-growth issues for gaps

---

## Zone 1 — Obligations

**O1 — SM §4g-anchor-parity runs every 10 SM cycles when `anchor.journeys_dir` is configured.**
Skip gracefully if not configured (no `journeys_dir` key in `anchor:` section).

**O2 — Reads ✅/[x] entries from AGENTS.md §Anchor section as the spec inventory.**
The spec inventory is the list of shipped specs that should have journey coverage.

**O3 — Fuzzy matches spec names against journey file names in the configured directory.**
A spec is considered journeyed if a file in `journeys_dir` contains the spec's normalized name.

**O4 — Posts parity ratio to REPORT_ISSUE.**
Format: `[SM §4g-anchor-parity | <session>] Spec→journey parity: N/M (X%)`

**O5 — Opens at most 3 anchor-growth issues per cycle for uncovered specs.**
Deduplicated by title prefix search. Priority/low, kind/chore.

**O6 — Skip gracefully when journeys dir not found or §Anchor section absent.**
No crash, no [NEEDS HUMAN], just a log message.

---

## Zone 2 — Implementer's judgment

- `anchor.journeys_dir` path is relative to repo root
- Fuzzy matching on normalized names (non-alphanumeric stripped, first 20 chars)
- Journey file extensions: `.ts`, `.js`, `.spec.ts`, `.spec.js`, `.py`, `.md`

---

## Zone 3 — Scoped out

- Transitive spec→journey chain analysis
- Generating journey file content (only opens issues, doesn't write code)
- Cross-project journey analysis
