# 36: Vision Pressure in COORD — Queue Prefers Design-Doc-Backed Items

> Status: Active | Created: 2026-04-20
> Applies to: otherness itself and all managed projects

---

## What this does

Today, COORD claims queue items in priority order (high → medium → low) without
considering whether the item is backed by the current vision pressure context.

The vision pressure prompt (injected into Step A of the scheduled workflow) generates
design doc Future items. But if the queue already has lower-priority items that don't
correspond to any design doc, COORD may claim those first — implementing chores and
housekeeping while the freshly-identified vision gaps wait.

This design doc makes COORD vision-pressure-aware. Items that trace to a design doc
with a `🔲 Future` item get a priority boost. Items that don't are deferred until
no design-doc-backed items remain.

---

## Present (✅)

*(Nothing shipped yet.)*

---

## Future (🔲)

- 🔲 36.1 — COORD §1b: read active design doc Future items at session start — before claiming any item, build an in-memory set of all `🔲 Future` items from `docs/design/*.md`. This is the "vision pressure set" for this session.
- 🔲 36.2 — COORD §1b: boost claim priority for vision-pressure items — when scanning open issues to claim, check if the issue title or body references a string from the vision pressure set (first 40 chars of any Future item). Issues that match are promoted to `priority/high` for claim purposes regardless of their label. Issues that don't match are treated as `priority/low` for claim purposes regardless of their label.
- 🔲 36.3 — COORD §1b: log vision-pressure claim decisions — when claiming an item, append to the batch report: "Claimed #N [vision-backed: yes/no] — <reason>". This makes the claim logic auditable without adding overhead.
- 🔲 36.4 — COORD §1f: queue-depth check accounts for vision pressure — the minimum queue depth guard (currently: if queue < 5, trigger learn/vision) should count only vision-backed items. A queue with 10 items that are all chores is effectively empty from a vision standpoint.
- 🔲 36.5 — SM §4f: report vision pressure utilisation — in the health comment, include: "Vision-backed items claimed this session: N / M total claims." This closes the feedback loop: the human can see whether the pressure prompts are actually driving what gets implemented.

---

## Zone 1 — Obligations

**O1 — Vision pressure boost is a tiebreaker, not an override.** If an item is `priority/critical` (e.g. a broken CI fix), it always claims first regardless of vision backing. The boost only applies within the same priority tier.

**O2 — An item with no design doc reference is not blocked.** It is deferred, not excluded. If the session exhausts all vision-backed items, it falls back to claiming non-backed items. The loop never idles waiting for vision-backed work.

**O3 — The vision pressure set is rebuilt every session.** It is not persisted to `_state`. Step A's commits land on main before Step B starts — COORD reads the current docs/design/ state as-is. This means Step A and Step B are naturally coupled: what Step A writes, Step B claims.

**O4 — Design doc number is not required — any reference counts.** An issue saying "implements accessibility WCAG 2.1 AA gaps from the donation readiness analysis" counts even if it doesn't say `docs/design/30`. The check is semantic (key phrase match), not structural (file path match). This prevents gaming via trivial doc references.

---

## Zone 2 — Implementer's judgment

- The vision pressure set build (§36.1) is a straightforward Python loop over `docs/design/*.md` — extract all `🔲 Future` lines, strip the `🔲 ` prefix, take first 40 chars of each. O(N) where N = total Future items, typically <100. Fast enough to run synchronously at session start.
- The claim boost (§36.2) does not need to be fuzzy. Exact substring match of the first 40 chars of any Future item in the issue title+body (case-insensitive) is sufficient. Fuzzy matching adds complexity with marginal benefit.
- §36.4 "vision-effective queue depth": implement as a separate count, not a replacement. Log both: `total_todo: N`, `vision_backed_todo: M`. Trigger learn/vision when `vision_backed_todo < 3` (not total_todo < 5).

---

## Zone 3 — Scoped out

- Cross-project vision pressure (kro-ui's pressure affecting kardinal-promoter's queue) — this is design doc 28 §Future cross-project propagation
- Reweighting items by how recent the corresponding design doc Future item is
- Automatic label application based on vision backing (would pollute issue labels)
