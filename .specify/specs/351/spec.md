# Spec: feat(sm): §4e arch_convergence > 0.7 → auto-trigger /otherness.learn issue

## Design reference
- **Design doc**: `docs/design/23-simulation-as-anchor.md`
- **Section**: `§ The arch_convergence signal`
- **Implements**: `SM §4e`: `arch_convergence > 0.7` → open learn trigger issue automatically (🔲 → ✅)

---

## Zone 1 — Obligations

**O1** — When `arch_convergence > 0.7` is detected during SM §4d calibration, the system opens a
GitHub issue labeled `otherness,area/agent-loop,kind/chore` with title format:
`learn(arch): arch_convergence at {score:.2f} — run /otherness.learn`

Violation: issue not opened, or opened with `needs-human` label, or opened with a different title format.

**O2** — The auto-triggered issue is deduplication-checked: if an open issue with the same title
prefix (`learn(arch):`) already exists, no second issue is opened.

Violation: two identical learn trigger issues opened for the same arch_convergence event.

**O3** — The existing `[NEEDS HUMAN]` issue creation is REPLACED, not supplemented.
The arch_convergence alarm no longer opens a `needs-human` issue.
It opens an `otherness`-labeled issue the COORD loop can pick up autonomously.

Violation: `[NEEDS HUMAN]` label on the arch_convergence issue.

**O4** — The issue body includes: `arch_convergence` score, threshold (0.7), and a
reference to `/otherness.learn` as the recovery action.

Violation: issue body missing score or recovery reference.

---

## Zone 2 — Implementer's judgment

- Whether to check for existing learn trigger issues using `gh issue list --search` or
  a `--json title` filter: `--search "learn(arch):"` is simpler and sufficient.
- Whether to post a comment on the report issue as well: yes, post a brief observation
  to maintain audit trail in the report issue.

---

## Zone 3 — Scoped out

- Executing `/otherness.learn` directly from SM (that is COORD's job when it claims the issue)
- Divergence detection (`todo_shipped < predicted_floor`) — separate issue 350
- Writing `sim-prediction.json` — separate issue 349
- Fleet defaults (`~/.otherness/scripts/sim-defaults.json`) — separate issue 353
