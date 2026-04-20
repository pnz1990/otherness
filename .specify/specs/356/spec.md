# Spec: feat(coord): anchor-growth gate

## Design reference
- **Design doc**: `docs/design/24-project-anchor-framework.md`
- **Section**: `§ Zone 1 — O1 Anchor growth precedes feature growth`
- **Implements**: COORD §1c anchor-growth gate — when coverage < coverage_target, generate anchor-growth items before feature items (🔲 → ✅)

---

## Zone 1 — Obligations

**O1** — During queue generation (§1c), check anchor coverage before generating feature items.
Read `anchor.coverage_target` from `otherness-config.yaml` (default: 80 if not set).
Check open `anchor:` issues AND AGENTS.md §Anchor section to determine if coverage is below target.

Violation: feature items generated when `open anchor: issues > 0` (already-queued anchor-growth items exist).

**O2** — If uncovered anchor-growth issues already exist in the queue (open issues with `anchor:` prefix),
log `[COORD §1c-anchor] Anchor-growth items in queue — skipping feature generation.` and skip feature generation this cycle.

Violation: feature items generated alongside open anchor-growth issues.

**O3** — If no anchor config exists in `otherness-config.yaml` (no `anchor:` section), skip the gate.

Violation: gate fires on projects without anchor config, blocking feature queue.

**O4** — The gate only fires if `anchor:` section exists in config AND coverage_target is set.
If `coverage_target` is 0 or absent: gate is disabled.

Violation: gate fires with coverage_target unset/zero.

---

## Zone 2 — Implementer's judgment

- How to measure current coverage from COORD without running SM: check count of open `anchor:` issues.
  If open anchor-growth issues exist, coverage is below target. This is a proxy, not exact.
- The gate checks at queue-gen time, not at claim time. This is correct behavior.

---

## Zone 3 — Scoped out

- Computing exact coverage ratio (that is SM §4g-anchor's job)
- Stagnation sessions check (future item 356b)
- Interleaving anchor and feature items (just blocking for now)
