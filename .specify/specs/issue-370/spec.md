# Spec: coord.md §1f Minimum Queue Depth Guard — Make Executable

## Design reference
- **Design doc**: `docs/design/22-queue-richness.md`
- **Section**: `§ Future — coord.md §1f: minimum queue depth guard executable`
- **Implements**: Replace [AI-STEP] comment with executable inline queue-gen (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1** — `coord.md §1f` must NOT contain `[AI-STEP: execute §1c queue generation block here]`. Violation: grep finds the comment.

**O2** — When QUEUE_REMAINING < 5 AND no queue-gen lock: the guard acquires the lock via `git push origin HEAD:refs/heads/otherness/queue-gen`, runs inline queue-gen python3, then releases the lock. Violation: lock not acquired/released.

**O3** — Inline queue-gen reads `docs/design/*.md` Future items, deduplicates against open issues (open_if_absent), creates max 10 issues. Violation: creates >10 issues or creates duplicates.

**O4** — Graceful fallback: if `git push` for lock fails (another session holds it): prints log message and skips. Violation: exception propagates.

**O5** — validate.sh and lint.sh pass. Violation: non-zero exit.

---

## Zone 2 — Implementer's judgment

- Lock acquisition uses the same branch as §1c queue-gen (otherness/queue-gen).
- open_if_absent uses the same gh CLI search pattern as §1c.
- Issue body template matches §1c format.

---

## Zone 3 — Scoped out

- Source priority cascade (roadmap → PM backlog → SM backlog) — separate item
- Roadmap fallback source — separate item
