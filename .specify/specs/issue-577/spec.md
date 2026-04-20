# Spec: Cross-Project Improvement Proposals — pm.md §5c executable

## Design reference
- **Design doc**: `docs/design/16-journey-2-reference-project.md`
- **Section**: `§ Future`
- **Implements**: cross-project improvement proposals — pm.md §5c [AI-STEP] → executable Python (🔲 → ✅)

---

## Zone 1 — Obligations

**O1**: pm.md §5c MUST execute cross-project analysis on every 10th PM cycle (PM_CYCLE % 10 == 0 AND PM_CYCLE > 0).

**O2**: For each project in `monitor.projects`: MUST check (a) open needs-human issue count, (b) CI status (last run conclusion).

**O3**: For each common blocker pattern found across ≥2 projects: MUST open a single improvement issue on `$REPO` with title format `improvement(loop): <abstract pattern> affecting ≥2 managed projects`. Must deduplicate (check if open issue with same title exists).

**O4**: If only 1 project in monitor.projects: MUST log "[PM] Need ≥2 projects for cross-project analysis." and skip.

**O5**: All API calls MUST be fail-open (try/except). A failed project check does not block analysis of other projects.

**O6**: validate.sh MUST pass after the change.

---

## Zone 2 — Implementer's judgment

- Which common patterns to detect: needs-human backlog, CI red, zero velocity (no recent PRs). Start with these 3.
- Issue labels: `otherness,kind/enhancement,area/agent-loop,priority/medium`.
- Whether to include project names in the issue body: no — abstract pattern descriptions only (per §5c design).

---

## Zone 3 — Scoped out

- Accessing internal state.json from managed projects (would require cross-repo state reads)
- docs/future-ideas.md scanning (step 5 of §5c — lower priority)
- Competitive scan / write_inferred_stub integration (step 6 — separate item)
