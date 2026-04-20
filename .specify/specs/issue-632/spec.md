# Spec: /otherness.status 3-line quick glance + design doc 06 update

## Design reference
- **Design doc**: `docs/design/06-command-surface.md`
- **Section**: `§ Future`
- **Implements**: /otherness.status single-page health summary readable in 30 seconds (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — Status output starts with a 3-line quick glance.**
The first 3 lines of /otherness.status output must answer: (1) health signal,
(2) last-shipped item, (3) queue depth. Everything else follows after.
Violation: first 3 lines do not answer all 3 questions.

**O2 — Design doc 06 updated with ✅ Present entry.**
The Future item for /otherness.status single-page health summary must be moved to
✅ Present in docs/design/06-command-surface.md.
Violation: design doc not updated.

---

## Zone 2 — Implementer's judgment
- PR #673 already shipped the 6-section dashboard. This PR adds a 3-line header above it
  and updates design doc 06.
- The 3-line format: "Health: X | Last: <PR title> | Queue: N todo"

## Zone 3 — Scoped out
- Condensing report issue comments (separate item)
