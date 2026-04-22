# Spec: issue-727 — PM §5o Patch Release Trigger (40.1)

## Design reference
- **Design doc**: `docs/design/40-autonomous-releases.md`
- **Section**: `§ Future`
- **Implements**: 40.1 — PM §5o patch release trigger (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — Patch trigger runs in PM phase every 3 PM cycles (N_PM_CYCLES gate).**
PM §5o is added after §5n. It checks whether to cut a patch release using the
criteria in design doc 40. It runs every 3 PM cycles, not every cycle.

**O2 — All five conditions must be true before cutting a patch release:**
1. Current latest tag is at least 7 days old (`releases.min_days_between`, default 7)
2. At least 3 PRs merged since last tag with `fix:`, `security:`, or `chore:` prefix
3. Zero `feat:` PRs merged since last tag (if feat: PRs exist → this is a minor, not a patch)
4. CI on main is green (last run conclusion = success)
5. No open `[NEEDS HUMAN]` issues

If any condition fails: do NOT cut the release. Log which condition failed.

**O3 — Opt-out via config.**
If `otherness-config.yaml` contains `releases: enabled: false` (or `releases.enabled: false`),
§5o is a no-op. Log: `[PM §5o] releases.enabled=false — skipped.`

**O4 — Deduplication: never create a release if one was already cut for the current HEAD.**
Before cutting, check that no tag points to the current HEAD commit.

**O5 — The release is cut with `gh release create "$NEXT" --title "..." --generate-notes --latest`.**
The tag format is `vX.Y.Z+1` (patch increment). If no existing tag: skip release (cannot
safely compute NEXT without a baseline tag).

**O6 — The action is reported to REPORT_ISSUE.**
After cutting (or not cutting with a reason), post a one-line comment on REPORT_ISSUE.

**O7 — `major_human_only: true` is never violated.**
This section only cuts PATCH releases (Z increment). It never increments X or Y.
It never creates a pre-release tag.

---

## Zone 2 — Implementer's judgment

- Where to read `releases.enabled`: parse `otherness-config.yaml` with regex (no PyYAML dependency).
- What counts as CI green: last run on main with conclusion=success. If no runs exist: treat as green (fail-open).
- `[NEEDS HUMAN]` check: `gh issue list --label needs-human --state open --jq 'length'`. If ≥1 → hold.
- Log format: `[PM §5o] ...` for all output.

---

## Zone 3 — Scoped out

- Minor and major release logic (items 40.2, 40.3)
- Release notes template with curated summary (item 40.4)
- `otherness-config.yaml` releases section validation (item 40.5, 40.6)
- Pre-release tags (alpha, beta, rc)
- CHANGELOG.md generation
