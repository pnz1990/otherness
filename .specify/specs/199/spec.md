# Spec: fix duplicate §1c section labels in coord.md (#199)

## Design reference
- N/A — infrastructure fix with no user-visible behavior change

## Zone 1 — Obligations

**O1** — `coord.md` has no duplicate section-level headings. All `## N<letter>` headings are unique.

Falsifiable: `grep "^## 1c" agents/phases/coord.md` returns exactly one match.

**O2** — The stale watchdog section is renamed `## 1d` and the claim section is renamed `## 1e`.

Falsifiable: `grep "^## 1d\." agents/phases/coord.md` returns one match containing "Stale".

**O3** — standalone.md §PARALLEL SESSION PROTOCOL reference to `§1c` is updated to match the new claim section label.

Falsifiable: `grep "§1c\|§1d\|§1e" agents/standalone.md` shows the reference points to the correct label.

## Zone 2 — Implementer's judgment

- Which becomes 1d/1e: stale watchdog → 1d (it runs before claiming), claim next item → 1e.

## Zone 3 — Scoped out

- Renumbering 1a/1b (not needed — those are unique).
