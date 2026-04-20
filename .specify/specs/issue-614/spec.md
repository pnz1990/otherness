# Spec: coord.md §1c Queue Refusal Guard

## Design reference
- **Design doc**: `docs/design/35-quality-of-output-gaps.md`
- **Section**: `§ Future`
- **Implements**: `coord.md §1c`: queue refusal guard — when all items in the queue are `kind/chore` or `kind/docs` (no `kind/enhancement` or `kind/bug`), trigger a minimum queue depth refresh from roadmap or autonomous vision before claiming the next item; a session that starts on a chore-only queue should inject ≥1 vision item first

---

## Zone 1 — Obligations

**O1**: When `§1e` selects the next item to claim, if ALL remaining `state=todo` items have labels in `{kind/chore, kind/docs}` (and none have `kind/enhancement` or `kind/bug`), the queue refusal guard MUST trigger before claiming any item.

**O2**: The guard triggers queue-gen from the next available source (design docs `🔲 Future` → roadmap → autonomous vision), creating ≥1 `kind/enhancement` item before the claim proceeds.

**O3**: The guard fires at `§1c` — not at `§1e`. It is a pre-claim enrichment gate that runs as part of queue generation when the queue is chore-only.

**O4**: The guard must not block indefinitely. If no enrichment source produces `kind/enhancement` items after one attempt, the guard logs a warning and allows claiming a chore item to avoid stalling.

**O5**: A comment is posted on the report issue when the guard fires, indicating it enriched the queue.

---

## Zone 2 — Implementer's judgment

- Implementation location: within `coord.md §1c`, after queue-gen determines the current queue composition, before the `§1e` claim step.
- Detection method: check `labels` field in `state.json` todo items; items without a `labels` array are treated as `kind/enhancement` (unknown = not chore).
- Enrichment source sequence follows `docs/design/22-queue-richness.md`: design docs first, roadmap second, then autonomous vision.

---

## Zone 3 — Scoped out

- Changing the priority ordering of chore items (handled separately in §1e).
- Queue refusal for other label conditions (only chore/docs purity triggers this).
- Blocking or cancelling chore items — they remain in the queue and are claimed after a `kind/enhancement` item is injected.
