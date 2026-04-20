# Spec: agents/onboard.md vision inference quality gate

## Design reference
- **Design doc**: `docs/design/35-quality-of-output-gaps.md`
- **Section**: `§ Future`
- **Implements**: `agents/onboard.md` vision inference quality gate: self-check after writing vision.md (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — Vision quality gate runs inline after STEP 4 (docs/aide/ creation).**
After the agent writes `docs/aide/vision.md`, a self-check block (STEP 4c) must
evaluate the quality of the written vision before proceeding to STEP 5.
Violation: gate absent; agent proceeds to STEP 5 with untested vision.

**O2 — Gate rejects visions under 100 words.**
If `wc -w docs/aide/vision.md` < 100, the agent must expand the vision before
proceeding. A vision under 100 words is by definition too abstract to be useful.
Violation: sub-100-word vision passes without expansion.

**O3 — Gate rejects visions without a named user/operator.**
The vision text must contain at least one "user noun" — a word identifying who
uses the product (e.g. engineer, developer, operator, admin, user, team, company,
customer, researcher). If absent, the agent must rewrite the "What This Is" paragraph
to name the user. Violation: vision passes with no user identified.

**O4 — Gate rejects visions with only generic value language.**
If the vision contains only phrases like "manages X efficiently", "makes Y easier",
or "helps with Z" without naming the specific mechanism or differentiator, the agent
flags it as generic and must add a specificity paragraph.
The check uses keyword matching: if the entire vision matches only generic phrases
(manage, efficiently, easier, helps, improve, support, provide) with no specific
technical term from the codebase, it fails.
Violation: generic vision passes without specificity review.

**O5 — If any gate fails, the agent revises inline and rechecks.**
Revision strategy: expand the vision by reading README again and adding missing
specifics. After revision, rerun the check (max 1 revision attempt).
Violation: gate fails but agent proceeds without revision.

---

## Zone 2 — Implementer's judgment

- STEP 4c is a bash block that calls python3 inline for the quality checks
- word count check: `python3 -c "print(len(open('docs/aide/vision.md').read().split()))"`
- user noun check: check for any of a ~15-word whitelist in vision text
- generic language check: if ratio of generic words to total is > 0.4, flag as generic
- Revision mechanism: [AI-STEP] the agent reads the vision and expands it inline before rechecking

---

## Zone 3 — Scoped out

- Semantic evaluation of vision accuracy (factual correctness)
- Cross-referencing vision against codebase to verify claims
- Checking every section in vision.md (only checks overall quality)
