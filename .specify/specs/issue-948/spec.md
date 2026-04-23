# Spec: issue-948

## Design reference
- **Design doc**: `docs/design/41-published-docs-freshness.md`
- **Section**: `§ Future`
- **Implements**: 41.5 — QA §3b: docs gate for user-visible features

---

## Zone 1 — Obligations (falsifiable)

**O1**: `agents/phases/qa.md` contains a `§41.5 docs gate` block inside the `§3b` spec conformance check.
- Verify: `grep -q '§41.5 docs gate' agents/phases/qa.md`

**O2**: The block fires only when a PR flips `🔲 → ✅` in a design doc (same condition as §41.4).

**O3**: User-visible check: the block classifies the feature as user-visible if the design doc item text contains `CLI`, `CRD`, `UI`, `endpoint`, `api`, `command`, `flag`, or `output` (case-insensitive).
- Verify: `grep -q 'cli\|crd\|user.visible' agents/phases/qa.md` (in the new block)

**O4**: The gate checks for a docs file in the diff: any file matching `docs/`, `README.md`, or `*.md` outside `agents/`, `.specify/`, `docs/design/`, `docs/aide/`. If none found AND feature is user-visible: WRONG finding.
- Verify: `grep -q 'docs.*file\|doc.*update' agents/phases/qa.md` (in block)

**O5**: If feature is NOT user-visible OR docs file is in diff: silently pass (no block).
- Verify: logic in the block handles both pass cases

**O6**: `docs/design/41-published-docs-freshness.md` has `41.5` moved from `🔲 Future` to `✅ Present`.
- Verify: `grep -q '✅ 41.5' docs/design/41-published-docs-freshness.md`

---

## Zone 2 — Implementer's judgment

- The block is placed inside the existing `§3b` bash block, after `§41.4 VERIFICATION GATE` closes (line ~334)
- Pattern: check `_FLIPS_CHECKMARK` (already computed for §41.4) to decide whether to run
- Fail-open: any error in the user-visible classification → skip (no false positives)
- "Docs file" definition: broad — any `.md` file except agents/, .specify/, docs/design/, docs/aide/ qualifies
- otherness PRs: agent instruction files are not user-visible. This gate is mostly relevant on managed projects (kardinal-promoter). On otherness itself: almost nothing is user-visible.

---

## Zone 3 — Scoped out

- Checking that the docs file content is accurate (too costly, judgment-heavy)
- Layer 1 auto-documentation check (no code-generated docs mechanism exists in otherness repo)
- Enforcing this retroactively on old PRs
