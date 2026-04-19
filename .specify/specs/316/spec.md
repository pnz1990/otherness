# Spec: COORD queue gen treats ⚠️ Inferred items as queue inputs

> Item: 316 | Created: 2026-04-19 | Status: Active

## Design reference
- **Design doc**: `docs/design/18-autonomous-vision-synthesis.md`
- **Section**: `§ Future`
- **Implements**: COORD queue gen: treat `🔲 ⚠️ Inferred` items identically to `🔲 Future` (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — The queue generation regex in coord.md §1c matches `🔲 ⚠️ Inferred` items.**
Currently COORD scans for `^- 🔲 (?!.*🚫)(.+)`. The `⚠️` Unicode character is not
in the exclusion set, so `🔲 ⚠️ Inferred: foo` is already matched. This must be
verified and confirmed in a spec, not assumed.

**O2 — The is_done() check treats `⚠️ Inferred` items the same as plain `🔲` items.**
When checking whether a design doc item is already in state or merged PRs, the
leading `⚠️ Inferred:` prefix is stripped before comparison so deduplication works.

**O3 — Design doc 18 marks this item ✅ Present.**

---

## Zone 2 — Implementer's judgment

- O1 is likely already true (regex doesn't exclude ⚠️). Verify by checking the
  actual regex and adding a test case comment.
- O2 requires a small change: strip `⚠️ Inferred: ` prefix in is_done() desc_key.

---

## Zone 3 — Scoped out

- Special handling for ⚠️ Inferred in issue titles or labels (same as any item)
