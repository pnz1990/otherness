# Spec: file_spaces — multi-session spatial coordination

> Item: 296 | Created: 2026-04-19 | Status: Active

## Design reference
- **Design doc**: `docs/design/15-multi-session-spatial-coordination.md`
- **Section**: `§ Future`
- **Implements**: state.json file_spaces field + coord.md §1e collision detection (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — coord.md §1e writes `file_spaces` to state.json when claiming an item.**
After the branch-push claim succeeds, the [AI-STEP] at §1e estimates the file spaces
the item will touch (based on its area label) and writes them to the feature entry in
state.json as `"file_spaces": ["src/components/", ...]`.

**O2 — coord.md §1e reads active file_spaces before claiming.**
Before pushing `feat/<item>`, the agent reads all `in_review` and `assigned` feature
entries from state.json and collects their `file_spaces`. If the candidate item's
estimated file_spaces overlap with any active declaration: skip to the next item.

**O3 — coord.md §1d stale watchdog clears file_spaces when a session heartbeat expires.**
If an assigned item has no heartbeat in >2h, its `file_spaces` is cleared alongside
the state reset to `todo`.

**O4 — An AREA_TO_SPACES map is defined in coord.md as a [AI-STEP] constant.**
The map covers at minimum: area/ui, area/controller, area/cli, area/docs, area/release,
area/graph, area/agent-loop.

---

## Zone 2 — Implementer's judgment

- All of this is [AI-STEP] comments in coord.md — no executable shell/python added.
  This is CRITICAL-B (additive comment content only).
- The file_spaces field is best-effort: if the area label is missing or unknown,
  file_spaces is set to [] (empty = no declared conflict, claim proceeds).
- Overlap detection: two file_spaces lists overlap if any string from one is a
  prefix of any string from the other (e.g. "src/" overlaps "src/components/").

---

## Zone 3 — Scoped out

- Actual file scanning to determine real file space (label-based estimation only)
- Cross-repo coordination (single repo per session)
- Retroactive detection of completed conflicts
