# Spec: issue-681 — test.sh recovery_action verification

## Design reference
- **Design doc**: N/A — infrastructure change to test tooling

## Zone 1 — Obligations (falsifiable)

**O1** — `scripts/test.sh` must attempt to read `_state:.otherness/sim-prediction.json`
from the reference project after the §5 alive check passes.
- Violation: no `sim-prediction.json` read attempt in test.sh.

**O2** — The check must warn (not fail) if `recovery_action` is absent from the file,
or if the file itself is absent.
- Violation: test.sh exits non-zero when `sim-prediction.json` is missing or lacks `recovery_action`.

**O3** — The check must print a labeled output line: `[5c] sim-prediction.json: ...`
showing the value found or a warning.
- Violation: no `[5c]` line in test output.

**O4** — `scripts/validate.sh` still passes (no regressions).
- Violation: validate.sh exits non-zero after this change.

---

## Zone 2 — Implementer's judgment

- Whether to use `gh api` or `git show` to read the file from the reference project _state branch
- Exact warning message wording
- Whether to export the found value for PM phase consumption

---

## Zone 3 — Scoped out

- Failing the test if recovery_action is absent (warn-only per issue spec)
- Validating recovery_action values beyond presence check
