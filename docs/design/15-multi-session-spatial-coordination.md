# 15: Multi-Session Spatial Coordination

> Status: Active | Created: 2026-04-19
> Applies to: all projects with max_parallel > 1

---

## The problem this solves

Three parallel sessions on kardinal-promoter all started within 30 seconds of each
other. Each claimed a different item using the branch-lock protocol. But two of the
three items (issue-799 responsive layout, issue-800 keyboard shortcut) both touched
overlapping files in the UI layer. When Session A merged its changes, Session B's PR
had conflicts. Session B spent time diagnosing an error it didn't cause.

The current claim lock (`git push origin feat/<item>`) prevents **item duplication**
but not **spatial collision** — two sessions claiming different items that touch the
same files.

This is the multi-agent monoculture risk in its practical form: agents working in
parallel on the same surface area, creating interference, wasting cycles on conflict
resolution that could have been avoided by better coordination.

---

## The coordination model: file-space declarations

When an item is claimed, the claiming agent **declares its file space** by writing
which top-level directories it will touch to `_state`. Before claiming an item,
an agent reads active file-space declarations and skips items whose expected file
space overlaps with a currently-active claim.

### File space declaration format (written to state.json)

```json
{
  "features": {
    "issue-799": {
      "state": "assigned",
      "file_spaces": ["src/components/", "src/styles/"],
      "assigned_at": "2026-04-19T03:24:57Z"
    }
  }
}
```

### Collision detection at claim time (coord.md §1e)

Before pushing `feat/<item>` to claim an item, the agent estimates which file spaces
the item will touch (based on issue title area tags: `area/ui`, `area/controller`,
`area/cli`, `area/docs`). It checks active `file_spaces` declarations in state.json.
If overlap: skip the item, pick the next non-overlapping item.

```python
AREA_TO_SPACES = {
    'area/ui': ['src/components/', 'src/styles/', 'src/hooks/'],
    'area/controller': ['internal/', 'pkg/', 'api/'],
    'area/cli': ['cmd/', 'internal/cli/'],
    'area/docs': ['docs/', 'README.md'],
    'area/release': ['.github/workflows/', 'Makefile'],
    'area/graph': ['internal/graph/', 'scripts/'],
}
```

### Staleness: file space declarations expire

A file-space declaration is stale if its `assigned_at` is >2 hours old AND the
session heartbeat has not updated in >2 hours. Stale declarations are cleared by
the stale watchdog in coord.md §1d.

---

## The deeper principle: complementary work

Three parallel sessions should always claim items that are **spatially complementary**
— working in different areas of the codebase simultaneously. This maximizes parallelism
and minimizes merge conflicts.

The queue generation phase (coord.md §1c) should, when generating multiple items at
once, prefer items from different `area/` labels so that parallel sessions naturally
spread across the codebase.

---

## Present (✅)

*(Not yet implemented.)*

## Future (🔲)

- 🔲 state.json: add `file_spaces` field to feature entries (written at claim time)
- 🔲 coord.md §1e: collision detection — read active file_spaces before claiming
- 🔲 coord.md §1d: stale watchdog clears file_space declarations >2h with no heartbeat
- 🔲 coord.md §1c: queue generation prefers spatially diverse items when generating batch
- 🔲 AREA_TO_SPACES: canonical map of area labels to file space patterns (config or hardcoded in coord.md)

---

## Zone 1 — Obligations

**O1 — Every claimed item has a file_spaces declaration in state.json.**
Written at claim time (§1e), before any implementation work begins.

**O2 — Claim protocol checks spatial overlap before claiming.**
If active file_spaces overlap with the candidate item's expected spaces: skip to next item.

**O3 — File space declarations expire with the heartbeat.**
If an assigned item has no heartbeat update in >2h, its file_spaces declaration is
cleared by the stale watchdog, making that space available to the next session.

**O4 — Queue generation spreads items across file spaces.**
When generating N items, prefer items from different area labels. Do not generate
3 UI items for 3 parallel sessions.
