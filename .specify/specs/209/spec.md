# Spec: 🚫 deprecated marker for design doc items (#209)

## Design reference
- **Design doc**: `docs/design/04-documentation-health.md`
- **Section**: `§ Future — Deprecated marker for design doc items`
- **Implements**: 🔲 Deprecated marker (🔲→✅)

## Zone 1 — Obligations

**O1** — COORD queue generation skips items containing 🚫 in the line.

Falsifiable: a design doc with `- 🔲 foo 🚫 Deprecated` produces zero queue issues for that item.

**O2** — Design doc 04 Present section updated.

**O3** — README (or a docs file) documents the three markers: ✅ Present, 🔲 Future, 🚫 Deprecated.

## Zone 2 — Implementer's judgment
- One-line regex change in coord.md queue-gen.
- Documentation in design doc 01 Zone 2 (implementer's judgment section).

## Zone 3 — Scoped out
- Retroactively marking any existing items as deprecated
- PM health scan detecting stale items (that is #208)
