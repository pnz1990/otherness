# Spec: CHANGELOG.md maintained automatically

**Issue**: #710

## Design reference

- **Design doc**: `docs/design/03-versioned-release.md`
- **Section**: `§ Future`
- **Implements**: CHANGELOG.md maintained automatically (🔲 → ✅)

---

## Intent

Each time SM §4 runs (after a batch), it appends an entry to CHANGELOG.md for each
merged PR in the batch. The human gets an up-to-date CHANGELOG without manual effort.

---

## Zone 1 — Obligations

**O1** — SM §4 (after §4a triage, before §4f health signal) runs a CHANGELOG update
step: for each PR merged since the last SM cycle, append an entry to CHANGELOG.md.

**O2** — CHANGELOG.md format follows Keep a Changelog conventions:
  `## [Unreleased]` section at top, each entry: `- <PR title> (#<N>)`

**O3** — The step is idempotent: if a PR entry is already present in CHANGELOG.md
(by PR number), skip it.

**O4** — CHANGELOG.md is committed directly to `main` via SM's direct-commit path
(same pattern as `docs/aide/progress.md` updates).

**O5** — If CHANGELOG.md does not exist, create it with the standard header.

**O6** — Design doc `docs/design/03-versioned-release.md` has this item flipped 🔲 → ✅.

---

## Tasks

- [AI] Add SM §4a-changelog step to agents/phases/sm.md
- [CMD] Flip design doc item 🔲 → ✅
- [CMD] Run validate.sh + lint.sh
