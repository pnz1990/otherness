# 49: Ninth Vision Scan — Pressure Gap Analysis (2026-04-23)

> Status: Active | Created: 2026-04-23
> Source: Ninth autonomous vision scan — SCAN 5 scored 0/5 pressure bullets (0%), all five lenses still open
> Applies to: otherness itself and all managed projects

---

## The problem

Eight prior vision scans (docs 46–48 + 35/37/39/45) have produced 200+ Future items
across five pressure lenses. SCAN 5 still scores 0/5 pressure bullets addressed. This
is no longer a coverage problem — the corpus is comprehensive. It is an **execution
sequencing problem**: the items exist but the most critical ones have not shipped.

This doc captures the genuinely new gaps not covered by any prior design doc item —
specific to the failure modes still live as of batch 11 / 2026-04-23.

---

## Present (✅)

*(Nothing shipped yet — this doc was created by the ninth vision scan.)*

---

## Future (🔲)

### Lens 1 — Reliability

- 🔲 49.1 — The 48-item corpus of reliability improvements has no triage priority signal — COORD cannot distinguish "which reliability item ships first for maximum session-output improvement": docs 35, 46, 48 collectively specify 40+ reliability Future items. COORD sees them as a flat list ordered only by priority/high vs. priority/medium label. But these items have a dependency ordering: shipping 48.3 ([ENG OUTCOME] comment) before 48.2 (stale watchdog root-cause) means the watchdog has structured data to read; shipping 46.2 (worktree cleanup) before 48.1 (size budget check) means the most common claim failure is already eliminated before adding a complexity gate. No design doc specifies the dependency graph or the minimum spanning path through the reliability items that produces maximum session-output improvement with minimum implementation effort. COORD §1d-chore-gate, when generating reliability issues, must read doc 48 §O3 priority ordering as its claim sequence. If the priority ordering in doc 48 §O3 is not reflected in GitHub issue priority labels: COORD must update the labels to match before claiming anything else. A flat priority label set on 40 reliability items wastes claim selection on any item when the highest-ROI item (the one all others depend on) is buried mid-list. The sequencing information exists in doc 48 §O3 but is not connected to COORD's claim logic. ⚠️ Inferred from reliability lens: a truly reliable system ships at least one meaningful PR every single run; the path to that outcome requires shipping reliability items in dependency order; the corpus has the ordering in doc 48 §O3 but COORD's claim logic does not read it.

- 🔲 49.2 — The "housekeeping PR with no real feature content" failure mode has a root cause that is missing from all diagnosis: when a session produces only housekeeping PRs, the current diagnosis path (doc 35, SM §4b chore-only AMBER) identifies the symptom. But no design doc item asks WHY the specific session produced a housekeeping PR — specifically: was the housekeeping PR the result of COORD's `chore-only guard` firing and falling through to chore claim (step 4 of the enrichment sequence), OR was the queue genuinely empty of feature items from the start? These have different fixes: the first requires improving the enrichment sequence; the second requires a vibe-vision scan. Doc 35 item "Per-session chore-output root cause" (35.x) specifies recording `chore_cause: queue_was_chore_heavy | coord_bypassed_feature_items`. But it does NOT specify what COORD or ENG must do DIFFERENTLY based on that cause in the same session — only how to diagnose it after the fact. The active fix at session time must be: if `chore_cause: coord_bypassed_feature_items` is detected by COORD §1b-session-type at session START: COORD must immediately trigger a vibe-vision inline scan (bypassing the normal queue) before claiming anything. If `chore_cause: queue_was_chore_heavy`: COORD must use the enrichment sequence. The cause → in-session-action mapping is missing. ⚠️ Inferred from reliability lens: housekeeping PRs are produced when the cause-to-action mapping is absent; detecting the chore cause at session start without changing behavior in the same session is diagnosis without treatment.

### Lens 2 — Honesty

- 🔲 49.3 — The `loop_honesty_score` (doc 45, item 45.1) has no minimum floor that prevents GREEN health from co-existing with a dishonest score below 50: item 45.1 states "when the score drops below 70: health must be AMBER regardless of other signals." But 45.1 has not shipped. Until it ships, there is no mechanism connecting the honesty score (if computed) to the health signal. More importantly: the spec says below-70 = AMBER but does not specify what below-50 triggers. A system that is 45% honest (delivering GREEN on its own metrics while 55% of its claims are unverifiable) should not be AMBER — it should be RED. The 45.1 spec must be extended: `honesty_score < 50` must trigger `health: RED` regardless of all other signals, with the note "🔴 RED — loop honesty score below 50: more than half of system claims are unverifiable. Loop may be self-reporting inaccurately." Without this RED threshold, a deeply dishonest system (45/100 honesty) looks exactly the same as a mildly dishonest one (68/100) — both are AMBER. The operator cannot distinguish "needs tuning" from "fundamental trust failure" from the health signal alone. ⚠️ Inferred from honesty lens: the SM health signal says GREEN but the products it manages are not advancing; the honesty score's AMBER threshold (70) is specified but the RED threshold (50) is not; a system below 50% honesty requires a different response from the operator than one below 70%.

- 🔲 49.4 — Simulation `arch_convergence` is read from `sim-prediction.json` but the file's last-write timestamp is never compared to the session count — a stale sim-prediction file is treated as current: COORD §1b-preflight reads `arch_convergence` from `_state:sim-prediction.json`. But if the simulation calibration has not run in 20 batches (because SM §4e was skipped, because calibrate.py errored, because the _state branch had a push conflict), the file's `arch_convergence` value is 20 batches old. COORD reads it and acts on it as if it is current — potentially applying DIVERSITY_MODE for a convergence score that was measured 20 sessions ago and may have resolved. COORD §1b-preflight must read two fields from `sim-prediction.json`: `arch_convergence` AND `calibrated_at_batch`. If `current_batch - calibrated_at_batch > 15`: treat `arch_convergence` as stale — do NOT apply DIVERSITY_MODE or any simulation-driven behavior; instead log: "COORD §1b: sim-prediction.json is 16+ batches old — treating as stale, ignoring arch_convergence recommendation." SM §4e must write `calibrated_at_batch: N` to `sim-prediction.json` at every calibration run. Without this staleness check, a single calibration error causes DIVERSITY_MODE to be applied (or not applied) for the next 50 batches based on 50-batch-old data — the simulation is driving behavior with incorrect inputs indefinitely. ⚠️ Inferred from honesty lens: the simulation exists but its predictions are not visibly changing agent behavior; one reason is that the simulation's output file may be stale while COORD treats it as authoritative; stale data driving behavioral changes is the opposite of honest simulation-behavior coupling.

### Lens 3 — Self-improvement

- 🔲 49.5 — The `/otherness.learn` agent has no session frequency guarantee — it can go 30 days without running and no mechanism surfaces this as a problem: doc 31 specifies learn frequency targets and the SM §4c skill-staleness check. But no item specifies what happens when learn sessions haven't run in N days. SM §4c checks skill age (via git log) and PROVENANCE.md mentions — but it checks skill FILES, not session recency. A codebase where no new skills have been added in 30 days has a different problem than one where skills exist but are stale. There is no `last_learn_session_at` field in `state.json` and no COORD behavior that changes when learn sessions haven't run recently. SM §4c must: (1) read `last_learn_session_at` from PROVENANCE.md (last entry date); (2) if `today - last_learn_session_at > 14 days` AND the skills library has not grown in that period: write `learn_session_overdue: true` to `state.json` and include in health comment: "⚠️ Last learn session: N days ago (target: ≤14 days)"; (3) COORD §1b-preflight must, when `learn_session_overdue: true`: open a `kind/chore priority/medium` issue "[LEARN OVERDUE] No learn session in N days — schedule /otherness.learn on an architecturally diverse repo" before claiming any other item. The 14-day target makes the self-improvement cadence explicit and detectable. Without this, the self-improvement claim is unfalsifiable between learn session runs — the system can go months without learning anything new while health remains GREEN. ⚠️ Inferred from self-improvement lens: /otherness.learn runs rarely; no mechanism surfaces learn session staleness as a gap in the health signal; a 14-day recency target with an explicit health comment field makes the learn frequency visible and actionable.

- 🔲 49.6 — The skills library's README.md is the index a new ENG session uses to decide which skill to load — but it has no "last effective date" or "confidence level" per skill: `agents/skills/README.md` lists all skills. ENG reads this to select the most applicable skill. But README.md has no metadata per skill entry: no date added, no confidence level (well-tested vs. experimental), no note on which agent versions it applies to. A skill added in batch 5 for the v0.1 agent architecture is listed side-by-side with a skill added in batch 100 for v0.2. ENG has no signal to prefer the recent skill. The skills README.md must be extended with a metadata table format: `| skill file | added | confidence | applies-to | last-validated |`. SM §4b must, when a new skill is added to `agents/skills/`, update the README.md table. `confidence` values: `experimental` (added by one learn session, not yet verified in production), `validated` (used in ≥3 ENG sessions with positive QA outcomes), `deprecated` (marked stale by decay check). ENG must prefer `validated` skills over `experimental` ones when both are applicable. Without confidence levels, ENG loads skills randomly from the index — the skill loading is not evidence-based and cannot improve over time. ⚠️ Inferred from self-improvement lens: the agents are not meaningfully smarter than they were two weeks ago; one reason is that the skill selection mechanism (README.md index) has no quality signal — all skills are presented equally regardless of age, validation status, or applicability to the current architecture.

- 🔲 49.7 — Frame-lock break protocol (doc 31) requires detecting `arch_convergence >= 0.65` for 3 consecutive calibrations — but calibration runs every 10 batches, meaning frame-lock is undetected for up to 30 batches after it begins: the frame-lock break protocol fires when `arch_convergence >= 0.65` for 3 CONSECUTIVE CALIBRATIONS. At 10-batch calibration cadence, this requires 30 batches of sustained frame-lock before any response. During those 30 batches, COORD continues claiming items with the same reasoning framework — amplifying the monoculture. An earlier detection mechanism is needed. SM §4e must add an interim-convergence tracker: after each calibration, if `arch_convergence >= 0.65` (even for the first time), write `frame_lock_early_warning: true` to `state.json`. COORD §1b-preflight, when `frame_lock_early_warning: true`, must: (1) log "COORD §1b: arch_convergence early warning — applying 20% diversity bonus to claims from docs 31/45/46"; (2) when selecting the next item, boost `kind/enhancement` items referencing skills-expansion or self-improvement docs by 20% in the priority sort (a soft nudge, not a hard DIVERSITY_MODE takeover). This early warning softly diversifies one batch before the full 3-calibration DIVERSITY_MODE triggers. The result: 10 batches of gentle frame-lock mitigation before 30 batches of the more forceful mode. Without the early warning, frame-lock goes fully unaddressed for 30 batches — the monoculture deepens before any response. ⚠️ Inferred from self-improvement lens: the "monoculture" problem has not been addressed; the frame-lock protocol exists but activates after 30 batches of confirmed lock; an early warning at batch 10 with a soft diversity nudge reduces the lock depth before it becomes severe.

### Lens 4 — Onboarding

- 🔲 49.8 — The onboarding guide's "What to expect" section (doc 48, item 48.11) has been specified but the verification commands it prescribes are not linked to any actual workflow step — a human must run them manually, which is the exact friction the item aims to eliminate: item 48.11 specifies that `onboarding-new-project.md` must add "After this step: run `<command>` — you should see `<expected output>`" after each major step group. This is correct. But 48.11 does NOT specify that these same verification commands must be available as a single runnable script. A human following a guide with 7 step-groups must manually run a different command after each step — the friction is distributed across 7 interruptions instead of eliminated. The fix requires two outputs from the 48.11 implementation: (1) the inline "after this step" narrative (as specified), AND (2) a `scripts/verify-setup.sh` that runs ALL 7 verification commands sequentially and outputs a PASS/FAIL table. The script must be runnable at ANY point in the onboarding (not just at the end) so a human who got stuck at step 4 can run it and see "STEPS 1-3: PASS, STEP 4: FAIL — reason: secret not found". The script is not a replacement for the narrative — it is a machine-readable complement. Item 46.11 specifies `scripts/verify-onboarding.sh` with 5 checks. This item extends that to 7 checks covering all guide step groups, with clear STEP N: PASS/FAIL output. Without the script, the 7 verification commands in the guide remain manual steps — the friction is documented but not eliminated. ⚠️ Inferred from onboarding lens: a new project added today would still require significant human intervention; the 48.11 item reduces friction by adding narrative guidance; this item ensures the guidance is also machine-verifiable via a single script that covers the full guide.

- 🔲 49.9 — `/otherness.onboard` produces `docs/aide/` files but never tests whether the generated vision.md is SPECIFIC enough to drive real queue items — generic visions produce generic queues: `agents/onboard.md` STEP 4c adds a vision quality gate (doc 35: ≥100 words, named user, specificity ratio < 35% generic filler). But "specificity ratio" is measured against generic filler words — it does not test whether the vision produces actionable design doc items. A vision.md that says "We want to build a platform that improves developer productivity" passes the 100-word and named-user checks but contains no concrete feature areas that COORD can translate into `🔲 Future` design doc items. The vision quality gate must add a fourth check: (4) feature-extraction test — run a regex scan against the generated vision.md to extract concrete feature nouns (nouns that appear more than once and are not generic: "performance", "reliability", "scalability" are generic; "OAuth flow", "rate limiting", "audit log" are specific). Require ≥3 specific feature nouns. If the vision has fewer than 3 specific feature nouns: the agent must revise inline, asking "What specific features differentiate this product?" The four-check gate converts vision.md from "good enough to pass review" to "specific enough to generate concrete queue items." Without the feature-extraction check, onboard.md produces vision documents that satisfy quality criteria without being useful for autonomous queue generation — the most important downstream use case. ⚠️ Inferred from onboarding lens: /otherness.onboard produces docs that need manual editing; the editing is specifically needed to add concrete feature specificity that the current quality gate does not require; a feature-extraction check at generation time prevents this class of post-onboarding edit.

### Lens 5 — Visibility

- 🔲 49.10 — The SM health comment format has grown to include 15+ fields across multiple docs (39.1, 46.4, 47.4, 48.13, etc.) but no single doc specifies the CANONICAL comment format — implementations are inconsistent and the comment is unreadable: doc 39 item 39.1 defines a structured health table with specific columns. Items 46.4, 47.4, 48.13, 48.15 each add new fields. The `[VIBE-VISION-AUTO]` comment, the `[SESSION OUTCOME | COORD]` breadcrumb (46.18), and the `<details>` block for plain-English summary (46.30) are all specified as separate additions. But no doc defines the FINAL canonical format of the single health comment after all these items are implemented — field ordering, header format, required vs. optional fields, maximum length. The result: each implementation PR interprets the spec independently; the comment grows with each addition; the 30-second readability goal (39.14) is never tested against the combined output. SM §4f must have a single "health comment schema" doc (this item) that specifies: (1) required fields in order: Health, Batch, Honesty, Pressure, Stage, Delivered, Queue; (2) optional fields in a `<details>` block: Sim, Fleet, Competitive; (3) plain-English section (46.30) in a second `<details>` block; (4) maximum visible (non-details) comment length: 10 lines. Any SM §4f implementation PR must validate its output against this schema. QA §3a must check that the merged comment does not exceed 10 visible lines. Without a canonical schema, the health comment becomes a technical dump that fails the 30-second readability test the whole visibility doc is built around. ⚠️ Inferred from visibility lens: the report issue comments are too verbose and technical; the root cause is not any single addition but the accumulation of fields from multiple uncoordinated specs; a canonical comment schema is the coordination mechanism that keeps the comment readable as new fields are added.

- 🔲 49.11 — There is no mechanism that verifies the three key questions are answerable in 30 seconds from any single GitHub URL — the visibility work can ship without ever testing the core user goal: docs 39, 46, 48 specify 30+ visibility improvements. Each individual item has its own "30-second test" requirement (doc 39, item 39.14). But there is no SESSION-LEVEL acceptance test that asks: "given only the current state of the GitHub repo (no local tools, no state.json, no auth beyond read access), can a human answer (1) is it healthy?, (2) what did it ship today?, (3) is it moving toward the vision? — in ≤30 seconds?" This test must be run EVERY 20 batches as a PM §5 check. The test procedure: (1) open `docs/aide/HEALTH.md` (when 48.15 ships) OR the report issue body (when 39.2 ships) — whichever exists; (2) start a 30-second timer; (3) record whether all three questions are answerable from that single URL before the timer expires; (4) if any question is unanswerable in 30 seconds: PM §5 must open a `kind/bug priority/high` issue with the specific question that failed and the specific gap in the current implementation. Without this periodic test, 30+ visibility items can ship while the core user goal ("can a human answer 3 questions in 30 seconds?") remains unmet — because the test was never run. The test is not a unit test; it is a user journey test that only PM can conduct. ⚠️ Inferred from visibility lens: there is no clean single-page health dashboard; the visibility work can ship incrementally without ever testing whether the aggregate result answers the human's actual questions; a periodic journey test prevents the sum from being less than its parts.

---

## Zone 1 — Obligations

**O1 — All items are fail-open.**
None of these items may block the main loop. Detection failures are logged; the loop
continues regardless.

**O2 — Items enter the queue via COORD §1d-chore-gate.**
This doc is the source. COORD reads `🔲 Future` items and creates GitHub issues.
No human intervention needed to queue them.

**O3 — Priority ordering within each lens.**
- Reliability: 49.1 (triage sequencing) → 49.2 (chore-cause in-session action)
- Honesty: 49.3 (honesty RED threshold) → 49.4 (stale sim-prediction check)
- Self-improvement: 49.5 (learn frequency guarantee) → 49.6 (skills README metadata) → 49.7 (frame-lock early warning)
- Onboarding: 49.8 (verify-setup.sh script) → 49.9 (vision specificity gate)
- Visibility: 49.10 (canonical health comment schema) → 49.11 (30-second journey test)

**O4 — Item 49.10 (canonical comment schema) is the coordination item for all visibility work.**
Every SM §4f PR that adds fields to the health comment must reference doc 49 item 49.10
as its format authority. A PR that adds a field not in the schema or violates the 10-line
visible limit must be rejected by QA.

**O5 — Item 49.11 (30-second journey test) runs every 20 batches, not just once.**
PM §5 must schedule this test and track its pass/fail history in `state.json`.
Three consecutive fails must open a `[NEEDS HUMAN: visibility-journey-failing]` issue.

---

## Zone 2 — Implementer's judgment

- 49.1 (reliability item triage): the dependency graph in doc 48 §O3 is the canonical
  source. COORD need only read that ordering — it does not need to recompute it.
- 49.3 (honesty RED threshold at 50): the RED threshold applies only AFTER 45.1 ships
  and the honesty score is actually computed. Until 45.1 ships: this item has no effect.
- 49.4 (stale sim-prediction): `calibrated_at_batch` is a new field — SM §4e must
  backfill it on the next calibration run if absent, using the current batch number.
- 49.5 (learn frequency guarantee): the 14-day target is a soft SLA. If /otherness.learn
  was blocked for operational reasons (no suitable repo available, API quota), the COORD
  issue should be `priority/medium`, not `priority/high`.
- 49.6 (skills README metadata): the `confidence` field transitions: `experimental` (default
  on add) → `validated` (SM §4b upgrades after 3 ENG sessions with positive QA) → `deprecated`
  (SM §4b decay check). The upgrade and deprecation steps must be automated — not manual.
- 49.7 (frame-lock early warning): the 20% priority boost is additive to the existing priority
  sort, not a replacement. A `priority/critical` item still outranks a `priority/medium` item
  even with the diversity boost applied to the latter.
- 49.9 (vision specificity gate): "specific feature noun" is defined as: a noun phrase
  that appears ≥2 times in the vision.md AND is not in a 50-word generic-tech-filler list
  (`performance`, `scalability`, `reliability`, `developer experience`, `automation`, etc.).
  The 50-word list must be hardcoded in the gate check, not dynamically generated.
- 49.10 (canonical comment schema): the 10-line visible limit counts only non-blank,
  non-HTML-tag lines outside `<details>` blocks. The limit applies to the final rendered
  output, not the raw Markdown source.
- 49.11 (30-second journey test): PM §5 performs this as a documentation-zone action — it
  reads public GitHub artifacts (issue body, docs/aide/ files) and opens an issue if the
  test fails. It does NOT change any agent files or behavior during the test run.

---

## Zone 3 — Scoped out

- Redesigning the health signal architecture (already specified in doc 45)
- Replacing COORD's claim logic with a dependency-graph planner (too complex; 49.1
  uses the existing priority label system with a new ordering source)
- Automated user research or A/B testing of health comment formats
- Onboarding documentation for non-GitHub project management tools
