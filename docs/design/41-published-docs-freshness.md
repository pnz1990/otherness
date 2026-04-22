# 41: Published Docs Freshness — User-Facing Site Always Reflects Reality

> Status: Active | Created: 2026-04-21
> Applies to: all projects with a published docs site (currently kardinal-promoter)

---

## What this does

A published docs site at a public URL is the product's public face. When a feature
ships and the docs site doesn't reflect it, users can't find it. When the README
says v0.5.0 and the product is at v0.8.1, the project looks abandoned.

This design doc specifies three mechanisms that together keep the published site
current without human intervention:

1. **Auto-generation pipeline** — CLI reference, API reference, and changelog are
   generated from code and deployed on every merge. No human writes these.

2. **PM freshness check** — PM §5j scans user-facing docs for stale version numbers,
   undocumented commands, and comparison claims that no longer match reality. Opens
   `kind/docs` issues automatically.

3. **QA gate** — any PR that ships a feature (marks `🔲 → ✅` in a design doc) must
   include a docs update if that feature is user-visible. No docs update = WRONG finding.

---

## The two-layer docs model for kardinal-promoter

```
Layer 1 — Auto-generated (always current by construction)
  docs/reference/cli/kardinal-*.md    ← generated from Cobra by hack/gen-cli-docs/main.go
  docs/reference/api.md               ← generated from Go types by gen-crd-api-reference-docs
  docs/changelog.md                   ← maintained by agent per release (design doc 40)

  Trigger: docs.yml fires on push to cmd/kardinal/** or api/v1alpha1/**
  Gap risk: ZERO — code and docs are the same artifact

Layer 2 — Human-authored (requires active maintenance)
  README.md                           ← version, status, feature summary
  docs/index.md                       ← landing page
  docs/comparison.md                  ← vs Kargo, vs GitOps Promoter
  docs/cli-reference.md               ← quick-reference (duplicates Layer 1 partially)
  docs/concepts.md, guides/*.md       ← explanatory content

  Trigger: docs.yml fires on push to docs/**
  Gap risk: HIGH — content drifts when features ship without doc PRs
```

The key architectural decision: **migrate `docs/cli-reference.md` from Layer 2 to Layer 1.**
Instead of a hand-authored quick-reference that drifts, generate it from the same Cobra
source as `docs/reference/cli/`. The `hack/gen-cli-docs/main.go` tool should emit both
the per-command detail pages AND a consolidated `docs/cli-reference.md` overview.

---

## Present (✅)

- ✅ `hack/gen-cli-docs/main.go` generates per-command pages in `docs/reference/cli/` (2026-04-20) ⚠️ Stale — referenced file not found
- ✅ `docs.yml` Step 4: verify CLI docs in sync — PR CI fails if `docs/reference/cli/` is stale (2026-04-20) ⚠️ Stale — referenced file not found
- ✅ `docs.yml` Step 1: auto-generate CLI docs on every push to `cmd/kardinal/**` (2026-04-20) ⚠️ Stale — referenced file not found
- ✅ `docs.yml` deploys to `pnz1990.github.io/kardinal-promoter` on every merge to main (2026-04-20) ⚠️ Stale — referenced file not found
- ✅ 41.4 — PM §5j-comparison: comparison doc accuracy check — scans `docs/comparison.md` ❌ rows, matches against design doc ✅ Present items, opens `kind/docs priority/medium` issue when row is stale. Graceful skip if comparison.md absent. Dedup: at most one open issue per row. Runs every N_PM_CYCLES. (PR #896, 2026-04-22)

## Future (🔲)

- 🔲 41.1 — `hack/gen-cli-docs/main.go`: emit `docs/cli-reference.md` as a consolidated overview in addition to per-command pages. Format: command table with description + link to detail page. Removes the hand-authored duplicate entirely. `docs.yml` verify step catches any drift. **This closes the 4 missing commands gap permanently.**
- 🔲 41.2 — `docs.yml` path triggers: add `README.md` and `docs/comparison.md` to the `paths:` list so a push touching either file triggers a docs build + deploy. Currently these files can change without a docs redeploy.
- 🔲 41.3 — PM §5j: version staleness check — scan `README.md` for version strings matching `v[0-9]+\.[0-9]+\.[0-9]+`. Compare against latest GitHub release tag. If >1 minor version behind: open `kind/docs priority/high` issue with the stale line and the correct value.
- ✅ 41.4 — see ✅ Present section above. (PR #896, 2026-04-22)
- 🔲 41.5 — QA §3b: docs gate for user-visible features — when a PR marks a `🔲 Future` item `✅ Present` AND the feature is user-visible (CLI command, CRD field, UI behaviour), QA checks that either (a) a docs file was modified or (b) the feature is auto-documented by Layer 1. If neither: WRONG finding with exact missing doc reference.
- 🔲 41.6 — Immediate fixes (not blocked on design completion): README version v0.5.0 → v0.8.1; comparison.md: Subscription watchers row flipped from ❌ to ✅.

---

## Zone 1 — Obligations

**O1 — The published site must reflect the current release within one session of that release.**
After every release cut (design doc 40), the agent checks `README.md` version string,
`docs/index.md` status, and `docs/changelog.md`. All three must reflect the new version
before the session ends. This is part of the release process, not a separate concern.

**O2 — `docs/cli-reference.md` must be generated, not authored.**
Once item 41.1 ships, any PR that hand-edits `docs/cli-reference.md` is a WRONG finding.
The file is owned by `hack/gen-cli-docs/main.go`. The generator is the source of truth.

**O3 — The docs verification step (Step 4 in docs.yml) must never be skipped.**
The `verify-cli-docs-sync` job runs on every PR touching `cmd/kardinal/**`. This is the
regression guard. `continue-on-error: true` or `if: false` on that step is a QA blocker.

**O4 — Comparison doc claims must be verifiable against design doc Present items.**
Every `✅` in `docs/comparison.md` must correspond to a `✅ Present` item in a design doc.
Every `❌` must correspond to either an open `🔲 Future` item or an explicit "not planned"
note. A comparison claim with no design doc backing is documentation debt.

---

## Zone 2 — Implementer's judgment

- For item 41.1: the consolidated `cli-reference.md` overview should contain a command
  table with name, one-line description, and a link to the detail page in `docs/reference/cli/`.
  The detail pages already have full usage, flags, and examples. Don't duplicate them.
- For item 41.3: version staleness check should only fire once per stale version, not
  every session. Use duplicate suppression on the issue title prefix `"docs: README version"`.
- For the `docs.yml` path triggers (41.2): `README.md` is at the repo root, not in `docs/`.
  The `paths:` list needs `- 'README.md'` explicitly.

---

## Zone 3 — Scoped out

- Versioned docs (mike plugin) — available but not needed at current scale
- PDF generation
- Translation/localisation
- Auto-generating `docs/concepts.md` or guides from code comments
