# Spec: deprecate otherness.cross-agent-monitor (#215)

## Design reference
- **Design doc**: `docs/design/06-command-surface.md`
- **Section**: `§ Future — Deprecate otherness.cross-agent-monitor.md`
- **Implements**: DEPRECATE verdict from command surface audit (🔲 → ✅)

## Zone 1 — Obligations

**O1** — `.opencode/command/otherness.cross-agent-monitor.md` is deleted.

Falsifiable: `ls .opencode/command/otherness.cross-agent-monitor.md` → file not found.

**O2** — `scripts/validate.sh` required file list no longer includes `otherness.cross-agent-monitor.md`.

Falsifiable: `grep "cross-agent-monitor" scripts/validate.sh` → no match.

**O3** — `agents/cross-agent-monitor.md` is NOT deleted — it is the underlying agent
that `otherness.status --fleet` delegates to. Only the command launcher is removed.

Falsifiable: `ls agents/cross-agent-monitor.md` → file exists.

**O4** — Design doc 06 `§ Present` updated to mark this item as done.

## Zone 2 — Implementer's judgment
- README update (removing cross-agent-monitor from command table) is part of issue #219, not this item.

## Zone 3 — Scoped out
- Modifying agents/cross-agent-monitor.md behavior
