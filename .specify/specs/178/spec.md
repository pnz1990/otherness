# Spec: fix(test): test.sh integration check __file__ bug

> Item: 178 | Risk: low | Size: xs

## Design reference
- N/A — infrastructure bug fix, no user-visible behavior change

---

## Zone 1 — Obligations

**O1**: test.sh must use a correct path to resolve otherness-config.yaml — not os.path.abspath(__file__) in a heredoc.
- **Falsified by**: REFERENCE_PROJECT remains empty after fix.

**O2**: After fix, test.sh integration check actually runs on the reference project (pnz1990/alibi).
- **Falsified by**: Integration check still skipped when otherness-config.yaml has monitor.projects.

---

## Zone 2 — Implementer's judgment
- Use SCRIPT_DIR (already defined in the shell) to construct the config path.
- Or use pure bash to parse the YAML.

## Zone 3 — Scoped out
- Does not fix the alibi stall (Journey 2 failure) — that's a separate [NEEDS HUMAN].
- Does not modify validate.sh or lint.sh.
