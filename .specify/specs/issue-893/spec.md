# Spec: issue-893 — PM §5k: Open README refresh PR when staleness score ≥ 2.0

## Design reference
- **Design doc**: `docs/design/39-autonomous-readme-refresh.md`
- **Section**: `§ Future`
- **Implements**: 39.3 — PM §5k: open README refresh PR with staleness score in body, labeled `kind/docs priority/low size/s` (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — When §5l computes score ≥ 2.0 and readme_refresh is not false, PM must attempt to open a README refresh PR.**
A session where staleness score ≥ 2.0 and no PR-open attempt was made violates this obligation.

**O2 — Duplicate suppression: at most one open README refresh PR at a time.**
Before creating a PR, PM checks `gh pr list` for an open PR whose title contains `docs(readme): refresh`. If one exists, no new PR is created.

**O3 — The PR body must contain the staleness score and its signal breakdown.**
A PR without `score=`, `days_stale`, `feat_prs_since`, `missing_present`, `missing_commands` in the body violates this obligation.

**O4 — The PR must be labeled `kind/docs`, `priority/low`, `size/s`.**
A PR missing any of these three labels violates this obligation.

**O5 — The PR title must match `docs(readme): refresh — staleness score <N.NN>`.**
Any other title format violates this obligation.

**O6 — If the AI rewrite step (39.2) has not run, the PR still opens with a stub README change.**
Specifically: when 39.2 is not implemented, PM §5k must still open the PR with a note in the body that the AI rewrite step (39.2) is pending. The score and signal data are sufficient to justify the PR's existence.

**O7 — An old open README refresh PR (>7 days) gets a comment asking why it hasn't been merged.**
PM checks age of any existing open README refresh PR. If age > 7 days, it posts a comment on it.

---

## Zone 2 — Implementer's judgment

- The AI rewrite step (39.2) is not yet implemented. The PR body should clearly note this and contain a placeholder README change (e.g., add/update a `<!-- last-refreshed: YYYY-MM-DD -->` comment) so the PR is not empty.
- The PR should be opened against main. If git push fails (e.g., nothing to commit), log a warning and skip — do not crash the PM loop.
- The PM cycle check `$((${PM_CYCLE:-0} % ${N_PM_CYCLES:-3})) -eq 0` governs §5l; §5k runs as a follow-on within the same §5l block when score ≥ 2.0.

---

## Zone 3 — Scoped out

- 39.2 (the AI rewrite step) — that is a separate issue
- 39.4 (duplicate suppression beyond the basic open-PR check) — basic dedup is required by O2; full 39.4 is a separate issue
- 39.5 (validate.sh check for README comment) — separate issue
- Multi-language README
- README translation
