# Spec: Learn session completion must be verified, not just queued

**Issue**: #650

## Design reference

- **Design doc**: `docs/design/31-stage-2-skills-expansion.md`
- **Section**: `§ Future`
- **Implements**: Learn session completion must be verified, not just queued (🔲 → ✅)

---

## Intent

The current SM §4c cadence check says "if a learn issue is open, cadence is satisfied."
But an open issue doesn't mean learning happened — it might have been open for days with
no one claiming it. The cadence clock must be based on PROVENANCE.md (proof of
completion), not issue existence (only proof of scheduling).

---

## Zone 1 — Obligations

**O1** — SM §4c cadence check: after detecting an open learn issue, also check how long
it has been open. If it has been open >7 days with no active learn branch: log a warning
and re-comment on the issue to escalate it (nudge vs. silent assumption it will be worked).

**O2** — The print message "Learn issue already open ({open_count}) — cadence reminder
satisfied." must be changed to distinguish between: issue <7 days old (normal) vs. issue
>7 days old (stale — learning not yet happening). For stale issues: print
"[SM §4c] Learn issue stale ({N}d open) — escalating priority."

**O3** — When a learn issue has been open >7 days without a learn branch: add a comment
on the issue body with "[SM §4c] Learn issue has been open {N}d — no feat/learn branch
detected. Escalating to re-claim in this session if possible." and update the issue
priority label to `priority/high` if not already.

**O4** — Fail-open: if GitHub API call to check issue age fails, treat as satisfied (don't
escalate). No blocking.

**O5** — Design doc `docs/design/31-stage-2-skills-expansion.md` has item flipped 🔲 → ✅.

---

## Tasks

- [AI] In §4c learn cadence block, when `open_count > 0`: also fetch the learn issue creation date
- [AI] Compute issue age in days
- [AI] If age >7 AND no active learn branch: post escalation comment, update priority label
- [AI] Change print message to distinguish stale vs. fresh open learn issue
- [CMD] Flip design doc item 🔲 → ✅
- [CMD] Run validate.sh + lint.sh

---

## Non-scope

- Not changing the 14-day PROVENANCE.md threshold
- Not changing the branch-active detection
- Not modifying issue creation logic (only escalation of existing issues)
