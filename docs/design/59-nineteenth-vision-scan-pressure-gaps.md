# Design Doc 59 — Nineteenth Vision Scan Pressure Gaps

**Vision scan date**: 2026-04-23
**Scan**: 19th autonomous run
**Pressure result**: SCAN 5 scores 5/5 via domain-noun matching (over-broad — all five lenses remain genuinely open)
**Backlog size**: 253 `🔲 Future` items across 62 design docs

---

## The problem

18 vision scans have run. Doc 58 added two precisely-scoped items (58.1–58.2). This
doc applies the same high-precision criterion: a gap must (a) be live today, (b) have NO
existing `🔲 Future` item covering it in any of the 62 design docs — verified by exhaustive
keyword search across all 253 items, and (c) fix directly reduces failure under one of the
five pressure lenses.

The keyword search covered 89 search terms across the five pressure lens domains. After
that exhaustive search, two genuinely absent gaps were found. All remaining pressure
failures are already covered by items in docs 46–58; those items have not yet shipped.
This doc does NOT re-describe covered gaps. It adds only what is demonstrably absent.

---

## Present (✅)

*(No items shipped yet — doc created by this scan)*

---

## Future (🔲)

### Lens 2 — Honesty: COORD never adjusts claiming confidence based on simulation prediction accuracy

- 🔲 59.1 — Doc 58.1 specifies that SM §4b must write a `prediction_accuracy_rate` to
  `state.json` and include it in the health comment after 5 `simulation_accuracy` ledger
  entries. Doc 58.1 Zone 3 explicitly scopes out the COORD weighting change as a
  "dependent follow-up." That follow-up is this item. No existing `🔲 Future` item in
  any of the 62 design docs specifies COORD reading `prediction_accuracy_rate` and
  adjusting its claiming confidence accordingly. The honesty failure is specific: the
  simulation can be systematically wrong (accuracy=40%) while COORD continues to weight
  its `arch_convergence` and `recovery_action` signals at 100% confidence — because no
  mechanism connects the accuracy measurement (SM §4b) to the claiming weight
  (COORD §1b-preflight). After 58.1 ships, the system will know the simulation accuracy
  rate but not use it. COORD §1b-preflight must: (1) read `prediction_accuracy_rate`
  from `state.json`; (2) if `prediction_accuracy_rate` is absent or < 0.5 (fewer than 5
  ledger entries, or accuracy below 50%): treat `arch_convergence` and `recovery_action`
  signals as LOW CONFIDENCE — do not suppress DIVERSITY_MODE below `arch_convergence=0.7`
  unless at least 5 ledger entries exist with `prediction_accuracy_rate >= 0.5`; (3) if
  `prediction_accuracy_rate >= 0.5` and ≥5 ledger entries: treat simulation signals at
  FULL CONFIDENCE as before; (4) include the confidence level in the COORD §1b-preflight
  log: "Sim confidence: HIGH (accuracy=N/5, 70%)" or "Sim confidence: LOW (accuracy=3/5,
  60% — below 0.5 threshold)". Without this item, the prediction accuracy ledger (58.1)
  is a measurement without consequence. The simulation can accumulate a 40% accuracy
  record while continuing to direct COORD behavior at 100% confidence — the honesty
  failure persists because detection (58.1) is decoupled from behavioral correction
  (this item). The two items are designed as a pair: 58.1 measures accuracy; 59.1 acts
  on it. A system that measures its own calibration without adjusting its behavior based
  on that calibration is not acting on its self-knowledge — which is the honesty lens
  failure at its deepest level. ⚠️ Dependent on 58.1 shipping first. COORD §1b-preflight
  change is safe to implement before 58.1 ships — when `prediction_accuracy_rate` is
  absent from `state.json`, the LOW CONFIDENCE path applies by default (conservative,
  not blocking).

### Lens 2 — Honesty: SM detects gap-doc coverage gap but does not fix it

- 🔲 59.2 — Doc 57.2 specifies that SM §4a must run a gap-doc triage check at session
  START and post AMBER when >50% of items in `docs/design/[4-9][0-9]-*.md` have no
  corresponding open GitHub issue. The current state: 102 items across docs 46–58 have
  0% issue coverage. 57.2 specifies DETECTION only — an AMBER signal. It does NOT specify
  REPAIR. No existing `🔲 Future` item in any of the 62 design docs specifies SM or
  COORD automatically creating GitHub issues for the top-priority unissued gap-doc items.
  The result: 57.2 fires AMBER every session, COORD sees AMBER, but the underlying cause
  (unissued items) cannot be fixed because COORD can only claim issues that exist — and
  the items have no issues. The gap-doc coverage gap is self-perpetuating: the detector
  fires but the repair mechanism does not exist. SM §4a must, when `unissued_count > 50`
  is detected (the same threshold as 57.2's AMBER trigger), auto-create GitHub issues for
  the top-5 highest-priority unissued items from gap docs, ranked by: (1) doc number
  (lower = older, more urgent), (2) obligation number within the doc (lower = more
  fundamental). The issue creation uses the existing pattern:
  `gh issue create --repo $REPO --title "feat: <first 80 chars of item>" --label
  "otherness,kind/enhancement,priority/high"
  --body "## Design reference\n- **Design doc**: docs/design/<fname>\n- **Obligation**: <item number>\n- **Implements**: <item text>\n\n## Why now\nSM §4a gap-doc triage detected {unissued_count} unissued gap-doc items. Auto-creating the top-5 to allow COORD to claim them."`.
  Cap at 5 new issues per session (to prevent queue flooding — same discipline as SCAN 3's
  cap of 5 inferred items per scan). Once COORD sees the issues, it can claim them in
  normal priority order. The AMBER signal persists until `unissued_count` drops below 50.
  This item is complementary to 57.2 (not a replacement): 57.2 detects and signals;
  59.2 repairs. Without 59.2, the AMBER signal created by 57.2 is a permanent fixture —
  the system correctly reports the gap but cannot close it. A system that detects its own
  failure and then takes no corrective action is detecting but not acting — the honesty
  gap is not closed by detection alone. ⚠️ Deduplication guard: before creating each
  issue, SM §4a must search open issues for title prefix matching. If a matching open
  issue already exists, skip that item. No duplicate issues per session.

---

## Zone 1 — Obligations

| # | Obligation |
|---|---|
| 59.1 | COORD §1b-preflight must read `prediction_accuracy_rate` from `state.json`. If absent or < 0.5: treat simulation signals (arch_convergence, recovery_action) at LOW CONFIDENCE — do not apply DIVERSITY_MODE based on arch_convergence alone; do not follow recovery_action without independent confirmation from queue state. If ≥ 0.5 with ≥5 ledger entries: treat at FULL CONFIDENCE. Log confidence level in preflight output. |
| 59.2 | SM §4a must, when gap-doc unissued count > 50 (same threshold as 57.2 AMBER trigger): auto-create GitHub issues for top-5 unissued items from docs/design/[4-9][0-9]-*.md, ranked by doc number then obligation number. Cap: 5 per session. Deduplication guard required. The AMBER signal (57.2) and issue creation (59.2) run as the same §4a step — detect and repair in one pass. |

## Zone 2 — Implementer's judgment

- 59.1: the LOW CONFIDENCE path must NOT block COORD from claiming. It adjusts the
  confidence weighting of the simulation signal, not the claiming decision itself. If
  simulation says `recovery_action=trigger_vision_synthesis` with LOW CONFIDENCE:
  COORD treats it as advisory (can override it with queue priority) rather than
  mandatory (cannot override it). The claim still happens; the simulation merely has
  less authority over which specific item is claimed.
- 59.1: `prediction_accuracy_rate` is absent from `state.json` until 58.1 ships and
  accrues 5 ledger entries. Until then, LOW CONFIDENCE is the correct default — not
  because the simulation is known to be wrong, but because its track record is unknown.
  The conservative path (treat unknown accuracy as LOW) avoids over-relying on a
  simulation that has never been validated.
- 59.2: the `docs/design/[4-9][0-9]-*.md` glob correctly targets gap analysis docs
  (46–99) while excluding core design docs (00–45) which already have issue coverage
  via the normal COORD claiming cycle. If a gap doc has a mix of issued and unissued
  items, only the unissued items are candidates for auto-creation.
- 59.2: the auto-created issue title format is `feat: <obligation number>: <first 70
  chars of item text>` (e.g. `feat: 59.2: SM §4a auto-creates issues for top-5
  unissued gap-doc items`). This keeps titles consistent with the existing queue format
  that COORD parses.

## Zone 3 — Scoped out

- 59.1 does NOT redesign the simulation model or the DIVERSITY_MODE trigger. It adds a
  confidence modifier on top of the existing simulation signal reading in COORD
  §1b-preflight. The simulation continues to write `arch_convergence` and
  `recovery_action` exactly as before; COORD simply weights them by the accuracy rate.
- 59.1 does NOT require 58.1 to be shipped first. The LOW CONFIDENCE default applies
  when `prediction_accuracy_rate` is absent — which is the correct starting state.
  The COORD change can ship independently of the SM change in 58.1.
- 59.2 does NOT create issues for ALL unissued gap-doc items. The 5-per-session cap
  is deliberate: at 102 unissued items, creating all 102 at once would flood the queue
  and prevent COORD from claiming other work types. The cap ensures steady progress
  (5 new gap-doc issues per session ≈ 20 batches to clear the backlog) while preserving
  queue balance.
- 59.2 does NOT close the AMBER signal in the same session it fires. The AMBER signal
  requires the unissued count to drop below 50 — which requires issued items to be
  CLAIMED and MERGED, not just created. The creation is the first step of a multi-batch
  repair cycle; the AMBER clears when the repair is complete.
