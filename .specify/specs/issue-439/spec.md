# Spec: kro-ui Anchor Score Comment Format (issue-439)

## Design reference
- **Design doc**: `docs/design/26-anchor-kro-ui.md`
- **Section**: `§ Future`
- **Implements**: Anchor score comment: E2E workflow posts `[ANCHOR | kro-ui | DATE] journeys: J | pass: A fail: B` to issue #439 (🔲 → ✅)

## Context

The kro-ui anchor score comment format defines how the E2E workflow reports anchor coverage.
The SM §4g-anchor-score section (implemented in PR #448) reads this via the generic `score_pattern`
regex from the project's `otherness-config.yaml`. The kro-ui-specific configuration will be:
```yaml
anchor:
  score_pattern: "journeys:\\s*(\\d+)\\s*\\|\\s*pass:\\s*(\\d+)"
```

The otherness-side implementation is the design doc update confirming the format is defined
and will be readable by the generic SM §4g-anchor-score once PR #448 is merged.

---

## Zone 1 — Obligations

**O1 — Design doc updated: kro-ui anchor score format moved from 🔲 Future to ✅ Present.**
The format `[ANCHOR | kro-ui | DATE] journeys: J | pass: A fail: B` is documented as the
standard comment format for kro-ui's E2E anchor. The SM reads it via score_pattern config.

**O2 — No agent code changes required (additive design doc update only).**
The generic §4g-anchor-score already handles this via score_pattern. No sm.md modification needed.

---

## Zone 2 — Implementer's judgment

- The kro-ui team must configure `anchor.score_pattern` in their `otherness-config.yaml`
  once they implement the E2E workflow comment posting.

---

## Zone 3 — Scoped out

- Modifying the kro-ui E2E workflow to post the comment (separate repo)
- Adding `anchor.score_pattern` to kro-ui's `otherness-config.yaml` (separate repo)
