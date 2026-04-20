# Spec: Dual-step scheduled workflow in otherness repo (issue-440)

## Design reference
- **Design doc**: `docs/design/28-dual-step-scheduled-workflow.md`
- **Section**: `§ Future`
- **Implements**: `otherness-scheduled.yml` split into two OpenCode steps (Step A: vibe-vision, Step B: run) (🔲 → ✅)

## Context

The scheduled workflow was already split into two OpenCode steps before this item was queued:
- Step 7: "Otherness — Vision scan (Step A)" — `continue-on-error: true`
- Step 8: "Run otherness" (Step B)

This item updates the design doc to reflect the shipped implementation.

---

## Zone 1 — Obligations

**O1 — Design doc 28 updated: dual-step workflow moved from 🔲 Future to ✅ Present.**
The `docs/design/28-dual-step-scheduled-workflow.md` Present section now accurately
reflects that `otherness-scheduled.yml` has Step A (vision scan) and Step B (run).

**O2 — N/A — no code change required (design doc update only).**
The workflow implementation predates this item. This is a documentation sync.

---

## Zone 2 — Implementer's judgment
- N/A

---

## Zone 3 — Scoped out
- Remaining Future items in design doc 28 (separate issues)
