# Spec: README health badge and "last shipped" line

**Issue**: #711

## Design reference

- **Design doc**: `docs/design/06-command-surface.md`
- **Section**: `§ Future`
- **Implements**: README health badge and "last shipped" line (🔲 → ✅)

---

## Intent

A human visiting the repo on GitHub.com has no at-a-glance signal of system health.
The README must include:
1. A GitHub Actions workflow badge pointing to `otherness-scheduled` workflow
2. A "Last shipped" line updated by SM §4f every batch: `**Last shipped:** <PR title> (<date>)`

---

## Zone 1 — Obligations

**O1** — `README.md` includes a workflow badge for `otherness-scheduled.yml` near the top.

**O2** — SM §4f (after posting health comment) updates a `**Last shipped:**` line in
`README.md` with the most recent non-chore merged PR title and date. Commits directly.

**O3** — The README update is idempotent: finds and replaces the existing "Last shipped"
line rather than appending.

**O4** — If `README.md` doesn't have a `**Last shipped:**` line, insert one after the
workflow badge line (or at the top after the title).

**O5** — Fail-open: if no non-chore PR is found, skip the update.

**O6** — Design doc `docs/design/06-command-surface.md` has item flipped 🔲 → ✅.

---

## Tasks

- [AI] Add workflow badge to README.md
- [AI] Add "Last shipped" stub line to README.md
- [AI] Add SM §4f README update step to agents/phases/sm.md
- [CMD] Flip design doc item 🔲 → ✅
- [CMD] Run validate.sh + lint.sh
