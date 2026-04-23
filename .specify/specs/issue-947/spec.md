# Spec: issue-947

## Design reference
- **Design doc**: `docs/design/41-design-doc-integrity.md`
- **Section**: `§ Future`
- **Implements**: 41.5 — Periodic full-sweep audit of all ✅ Present items every 30 batches

---

## Zone 1 — Obligations (falsifiable)

**O1**: `agents/phases/pm.md` contains a `## 5r. Periodic ✅ Present audit` section.
- Verify: `grep -q '## 5r. Periodic' agents/phases/pm.md`

**O2**: Section fires every 30 PM cycles (uses `pm_audit_cycle` counter, mod 30).
- Verify: `grep -q 'pm_audit_cycle' agents/phases/pm.md`

**O3**: Categorizes each Present item as A (validate.sh), B (state evidence), C (PR reference), or D (unverifiable).
- Verify: `grep -q "category.*[ABCD]\|A.*validate\|B.*state\|C.*PR\|D.*unverif" agents/phases/pm.md`

**O4**: Reports if category C+D count exceeds 30% of total Present items on REPORT_ISSUE.
- Verify: `grep -q '30.*percent\|0\.3\|30%\|category.*D\|D.*unverif' agents/phases/pm.md`

**O5**: `docs/design/41-design-doc-integrity.md` has 41.5 moved from `🔲` to `✅`.
- Verify: `grep -q '✅ 41.5' docs/design/41-design-doc-integrity.md`

---

## Zone 2 — Implementer's judgment

- Section number: §5r (after §5q — minor release trigger)
- Cycle gate: every 30 PM cycles to avoid overfiring
- Categorization is heuristic: category A if item text references validate.sh/test/lint/scripts; B if references state.json/metrics; C if has PR # in text; D if none of the above
- Report threshold: 30% category C+D triggers a comment on REPORT_ISSUE (not a blocking issue)
- Fail-open: any API/read error skips the audit silently

---

## Zone 3 — Scoped out

- Automatically fixing category D items — that requires human judgment
- Retroactively re-running validate.sh to verify items — too expensive
- Per-item verification commands — scoped to 41.3 (already done)
