# Spec: issue-883 — Post-run assertion in GitHub Actions job summary (28.2)

## Design reference
- **Design doc**: `docs/design/28-dual-step-scheduled-workflow.md`
- **Section**: `§ Future`
- **Implements**: 28.2 — Step B must emit a post-run assertion in the GitHub Actions job summary confirming whether the run met the per-run meaningful-PR contract (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1** — A new step (Step 9) is added to `otherness-scheduled.yml` immediately after Step 8 (Run otherness). It must execute on every run regardless of Step 8's outcome (`if: always()`).

**O2** — The step reads `meaningful_prs` from `state.json` on the `_state` branch via `git show origin/_state:.otherness/state.json`. The field read is `last_session_prs` (integer). If `last_session_prs` is unavailable or unparseable, the step falls back to `last_session_vision_backed` (if present), then falls back to `0`.

**O3** — If `last_session_prs == 0` (or fallback resolves to 0): the step emits `echo "::warning::Run completed with 0 meaningful PRs — throughput principle not met. Session shipped chores only or no PRs." >> $GITHUB_STEP_SUMMARY`. The job must NOT fail (exit 0).

**O4** — If `last_session_prs >= 1`: the step emits `echo "✅ Meaningful PRs shipped: N" >> $GITHUB_STEP_SUMMARY` where N is the actual count.

**O5** — The step also emits session health signal: `last_session_health` from `state.json` if present (GREEN/AMBER/RED), appended to the summary line.

**O6** — The step must not fail the job. Use `if: always()` and `exit 0` regardless of `state.json` availability. If `_state` branch doesn't exist or `state.json` is missing, emit `echo "::notice::Post-run assertion: state.json unavailable — skipping." >> $GITHUB_STEP_SUMMARY` and exit 0.

**O7** — The design doc `docs/design/28-dual-step-scheduled-workflow.md` must be updated: the `28.2` item moves from `🔲` to `✅ Present`.

---

## Zone 2 — Implementer's judgment

- The step uses plain `bash` (no `uses:` action dependency) — it only needs git and python3, both available on ubuntu-latest.
- `git fetch origin _state` is required before `git show` to ensure the remote ref is available in the runner's clone.
- The step is named "Post-run assertion (Step 9)" for clarity in the Actions UI.
- Session health is appended on the same summary line for compactness: `✅ Meaningful PRs shipped: 2 | Health: GREEN`.

---

## Zone 3 — Scoped out

- Writing to Actions annotations (`::`error::`) that would fail the job — O3 explicitly requires `::warning::` only.
- Modifying Step B's exit code based on meaningful PR count.
- Posting to the report issue from this step (SM already does this).
- Adding this step to workflows for managed projects (out of scope for this issue).
