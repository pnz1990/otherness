# Spec: issue-639 — SM §4f VISION_PR_COUNT check (35.1)

## Design reference
- **Design doc**: `docs/design/35-vision-alignment-signal.md`
- **Section**: `§ Future`
- **Implements**: 35.1 — SM §4f: VISION_PR_COUNT check (🔲 → ✅)

---

## Zone 1 — Obligations

**O1** — `SM §4f` computes `VISION_PR_COUNT`: for each PR merged this session, check whether its title or body contains `docs/design/` or `🔲 →` or `design doc` (case-insensitive). Count the matching PRs. Exclude PRs whose titles match `^chore\(sm\)|^chore\(metrics\)|batch \d+|session complete` per design doc O3.

**O2** — If `VISION_PR_COUNT == 0` after a full session: health signal degrades to AMBER, regardless of CI status.

**O3** — `state.json` gains a `vision_aligned` boolean field (true if `VISION_PR_COUNT > 0`, false otherwise), written to `_state` each batch by SM §4f.

**O4** — The existing `VISION_PRS` metric (title-based) is separate from `VISION_PR_COUNT`. `VISION_PR_COUNT` uses body content scan (first 500 chars); `VISION_PRS` uses title pattern. Both coexist. `VISION_PR_COUNT` is the gating metric for health signal degradation (design doc O2).

**O5** — scripts/validate.sh PASSED, scripts/lint.sh PASSED.

---

## Zone 2 — Implementer's judgment

- Body scan: use `gh pr view --json body` for each PR merged this session. First 500 chars of body is sufficient.
- Session window: use the last 24 hours (consistent with existing MERGED count pattern).
- `vision_aligned` is written after computing `VISION_PR_COUNT`.
- Implementation location: SM §4f, after the `THROUGHPUT_WARN` block and before posting the health report.

---

## Zone 3 — Scoped out

- 35.2 (AMBER note text), 35.3 (two-consecutive trigger), 35.4 (COORD claim preference), 35.5 (state.json `vision_aligned` persistent) are separate issues — not in this PR.
- Actually: O3 above covers 35.5 minimally (the field is written) but 35.3 (two-consecutive-AMBER logic) is a separate item.
