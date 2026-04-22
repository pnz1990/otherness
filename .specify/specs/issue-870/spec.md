# Spec: issue-870 — SM §4f health AMBER when 0 meaningful PRs

## Design reference
- **Design doc**: `docs/design/21-session-throughput.md`
- **Section**: `§ Future`
- **Implements**: Health signal must degrade to AMBER when 0 meaningful PRs shipped (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1**: SM §4f must check `MEANINGFUL_PRS` before finalising the health signal.
If `MEANINGFUL_PRS == 0` AND `HEALTH == GREEN`, SM §4f must set `HEALTH=AMBER`.

*Falsified by*: HEALTH stays GREEN in §4f when MEANINGFUL_PRS is 0.

**O2**: The health comment must include a reason line when AMBER is set due to 0 meaningful PRs:
`"⚠️ AMBER — 0 meaningful PRs this session (chore-only or zero-ship)"`

*Falsified by*: health comment posts without this reason when MEANINGFUL_PRS==0 triggers AMBER.

**O3**: The check must not override a RED condition (CI red takes precedence).

*Falsified by*: HEALTH is downgraded from RED to AMBER when MEANINGFUL_PRS==0.

**O4**: The check must be fail-open — if MEANINGFUL_PRS is unset, treat as non-zero (assume work shipped).

*Falsified by*: SM §4f sets AMBER when MEANINGFUL_PRS is unset.

---

## Zone 2 — Implementer's judgment

- Add the MEANINGFUL_PRS==0 check AFTER the STABLE/STALLED→AMBER upgrade and BEFORE the sim calibration staleness check in §4f.
- The check reads MEANINGFUL_PRS from §4b (already set as env var).
- The reason line goes into a variable `_MEANINGFUL_WARN` appended to the health table.

---

## Zone 3 — Scoped out

- Does NOT change how MEANINGFUL_PRS is computed (that's §4b's job).
- Does NOT open an issue for 0 meaningful PRs (separate design doc item).
- Does NOT apply to the §4b report body (§4b already handles it).
