# Spec: anchor: section in kro-ui otherness-config.yaml

## Design reference
- **Design doc**: `docs/design/26-anchor-kro-ui.md`
- **Section**: `§ Future`
- **Implements**: otherness-config.yaml: `anchor:` section — score_pattern for `[ANCHOR | kro-ui]`, coverage_target: 60, stagnation_sessions: 5 (🔲 → ✅)

---

## Zone 1 — Obligations

**O1**: `kro-ui/otherness-config.yaml` MUST contain an `anchor:` section with the following fields:
- `score_pattern`: regex that matches `[ANCHOR | kro-ui | <date>]` lines posted to issue #439
- `coverage_target`: integer `60` (minimum depth score % for kro-ui)
- `stagnation_sessions`: integer `5` (sessions without anchor growth before COORD prioritizes)

**O2**: The `score_pattern` MUST match the format defined in docs/design/26-anchor-kro-ui.md:
`[ANCHOR | kro-ui | YYYY-MM-DD] journeys: J | pass: A fail: B`
A pattern that does not match this format violates O2.

**O3**: `docs/design/26-anchor-kro-ui.md` MUST have the `anchor:` section Future item moved from 🔲 to ✅ Present, with PR reference and date.

**O4**: `otherness-config-template.yaml` MUST include the `journeys_dir` field in its anchor section comment since kro-ui uses it — ensuring the template stays current with real usage.

---

## Zone 2 — Implementer's judgment

- The `score_pattern` regex may use either the full anchor format or the simplified one (journeys/pass/fail); the simplified format is what's currently posted so use it.
- Whether to add `journeys_dir` to kro-ui's config: the SM §4g-anchor-parity reads this field. Add it pointing to `test/e2e/journeys/`.
- The `anchor.workflow` field: kro-ui uses `e2e.yml`. Set it.

---

## Zone 3 — Scoped out

- Implementing the anchor workflow itself (already exists in kro-ui)
- Changes to SM §4g-anchor logic
- Updating other managed project configs (kardinal-promoter, alibi)
