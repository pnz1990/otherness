# Spec: Cross-project pressure propagation

## Design reference
- **Design doc**: `docs/design/28-dual-step-scheduled-workflow.md`
- **Section**: `§ Future`
- **Implements**: Cross-project pressure propagation: when otherness identifies a pattern (e.g. "test coverage at edge cases is weak across all 3 projects"), it should update all 3 project pressure prompts — not just its own. (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — SM §4c cross-project pattern detection triggers pressure propagation.**
When SM §4c detects a qualifying cross-project pattern (appearing in ≥2 monitored projects),
it must check each monitored project's scheduled workflow file for a pressure block
(`Context for this vision scan:`) and add a `🔲 Rewrite vision pressure context` item
to that project's relevant design doc. Violation: pattern detected but only current project
gets the pressure update.

**O2 — Propagation writes design doc items, not direct workflow edits.**
The propagation must add `🔲 Future` items to the monitored project's design docs
(via a PR to that repo), not directly edit the workflow YAML. Direct YAML edits bypass
the D4 design-first flow. Violation: agent directly modifies `.github/workflows/` in a
monitored project.

**O3 — Propagation issues are scoped to the specific monitored repo.**
The issue created for a remote project must be opened on that project's repo
(e.g. `gh issue create --repo pnz1990/kardinal-promoter`), not on `pnz1990/otherness`.
Violation: cross-project pattern issue opened on the wrong repo.

**O4 — No duplicate issue creation.**
Before creating a cross-project pressure issue, SM must check whether an open issue
with title containing "cross-project pressure" or "Rewrite vision pressure context"
already exists on the target repo. If it exists, skip. Violation: duplicate issues
created on monitored repos.

**O5 — Propagation runs only when ≥2 different projects share a pattern.**
A single-project pattern must not trigger cross-project propagation.
Violation: pattern from one project causes issues to be opened on other projects.

**O6 — SM §4c logs what was propagated.**
After propagation runs, SM must post a comment to `$REPORT_ISSUE` with a summary
of which projects received pressure updates and what pattern was detected.
Violation: propagation runs silently with no audit trail.

---

## Zone 2 — Implementer's judgment

- Pattern extraction algorithm: SM should detect recurring root causes by keyword
  matching across `needs-human` issue titles and bodies (same as existing §4c pattern
  mining). Pattern qualifies if keywords appear in ≥2 projects.
- Where to write the Future item on the monitored project: to the most relevant open
  design doc, or to a new `docs/design/28-` equivalent if none exists. Prefer the doc
  that already covers scheduled workflow / vision pressure.
- Timing: propagation runs in the same SM §4c cycle as cross-project pattern mining
  (every 5 SM cycles when `BATCH_COUNT % 5 == 0`).
- Whether to open a full PR on the monitored project: no. A `gh issue create` on the
  target repo is sufficient. The agent running on that project will pick up the issue
  in its next session.

---

## Zone 3 — Scoped out

- Directly editing workflow YAML files on monitored projects
- Synchronizing the full pressure block content (only flags the need for a rewrite)
- Real-time propagation (runs at SM §4c cadence, not on every merge)
- Projects not in `monitor.projects` in `otherness-config.yaml`
