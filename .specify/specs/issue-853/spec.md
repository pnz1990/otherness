# Spec: issue-853 — YAML syntax validation for scheduled workflow

## Design reference
- **Design doc**: `docs/design/28-dual-step-scheduled-workflow.md`
- **Section**: `§ Future`
- **Implements**: 28.1 — Scheduled workflow YAML syntax must be validated after every Step A commit (🔲 → ✅)

---

## Zone 1 — Obligations

**O1** — `scripts/validate.sh` must add a YAML syntax check for `.github/workflows/otherness-scheduled.yml` using `python3 -c "import yaml; yaml.safe_load(open('...').read())"`. If the file is invalid YAML: exit 1 with message: "FAIL: otherness-scheduled.yml has invalid YAML syntax — likely caused by a broken SCAN 5 pressure rewrite. Restore the file or fix the indentation."

Falsifiable: a workflow file with intentionally broken YAML (e.g. an unclosed string or wrong indentation) must cause validate.sh to exit 1 with the exact message above.

**O2** — The YAML check must only run when the workflow file exists (i.e. when `schedule.cron` is configured AND the workflow file is present). If the file is absent: skip the check silently (do not fail).

Falsifiable: running `bash scripts/validate.sh` on a repo without `.github/workflows/otherness-scheduled.yml` must not exit 1 due to this check.

**O3** — `agents/vibe-vision-auto.md` SCAN 5 must include a post-write YAML validation guard: after any future write to `.github/workflows/otherness-scheduled.yml` (when §37.5 is implemented), SCAN 5 must validate the file with `python3 -c "import yaml; yaml.safe_load(...)"`. If invalid: SCAN 5 must revert to the previous content and log the error to the report issue.

Falsifiable: the guard must be present as executable python/bash in SCAN 5. When triggered with an intentionally invalid write (simulated), the guard must restore the file and emit a `[SCAN 5 YAML ERROR]` message.

**O4** — The validate.sh YAML check must integrate naturally into the existing check numbering (add as a new numbered check, not as an appendix).

Falsifiable: the check must appear as `[N/M] Checking...` consistent with existing checks.

**O5** — The YAML check must use only Python stdlib (`yaml` is part of stdlib via `import yaml`). No external dependencies.

Falsifiable: running `python3 -c "import yaml"` on the CI runner must succeed without pip install.

---

## Zone 2 — Implementer's judgment

- The YAML check in validate.sh belongs after the existing check that verifies the scheduled workflow exists (currently the conditional block checking `SCHEDULE_CRON`). This keeps workflow-related checks co-located.
- For the SCAN 5 guard in vibe-vision-auto.md: since §37.5 (the actual workflow file rewrite) is not yet implemented, the guard should be placed as a clearly-labelled `[AI-STEP]` near the SCAN 5 section, explaining: "When implementing §37.5, run YAML validation here before committing."
- The `yaml` module in Python 3 is `PyYAML` — available in most Python 3 distributions but not always on minimal CI runners. The validate.sh check should include a `python3 -c "import yaml" 2>/dev/null || python3 -c "import sys; sys.exit(1)"` guard and skip with a warning if PyYAML is unavailable.

---

## Zone 3 — Scoped out

- Implementing §37.5 (the actual SCAN 5 workflow file rewrite) — this spec is a prerequisite guard, not the rewrite itself
- YAML validation for any other workflow files besides `otherness-scheduled.yml`
- Automatic YAML repair (out of scope — revert is the correct action)
