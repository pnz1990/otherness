# Spec: issue-909

## Design reference
- **Design doc**: `docs/design/40-autonomous-releases.md`
- **Section**: `§ Future`
- **Implements**: 40.2 — PM §5q (formerly §5l per design doc, but §5l is taken): minor release trigger

---

## Zone 1 — Obligations (falsifiable)

**O1**: `agents/phases/pm.md` contains a `## 5q. Minor release trigger` section after `§5p`.
- Verify: `grep -q '## 5q. Minor release trigger' agents/phases/pm.md`

**O2**: Section fires every 5 PM cycles (controlled by `pm_minor_cycle` counter, mod 5).
- Verify: `grep -q 'pm_minor_cycle' agents/phases/pm.md`

**O3**: All 6 conditions checked: tag ≥7 days, ≥3 feat PRs since tag, ≥1 new ✅ Present item, CI green, no needs-human issues, no open in_review feature PRs.
- Verify: `grep -q 'feat_count >= 3' agents/phases/pm.md` (or equivalent)

**O4**: Uses `gh release create` with `--generate-notes` when all conditions met. Auto-cuts `vX.Y+1.0`.
- Verify: `grep -q "release create.*generate-notes" agents/phases/pm.md`

**O5**: Opt-out via `releases.enabled: false` in config. Dedup: check for existing minor release open PR/tag.
- Verify: `grep -q 'releases_enabled' agents/phases/pm.md` (in §5q block)

**O6**: `docs/design/40-autonomous-releases.md` has `40.2` moved from `🔲 Future` to `✅ Present`.
- Verify: `grep -q '✅ 40.2' docs/design/40-autonomous-releases.md`

---

## Zone 2 — Implementer's judgment

- Section number: §5q (§5l is README staleness, §5o is patch, §5p is major detection)
- Pattern mirrors §5o (patch trigger): same structure, same cycle gate mechanism
- `pm_minor_cycle` counter (separate from `pm_patch_cycle`) to avoid coupling
- For computing "new Present items since last tag": use git log to find design doc changes
- Curated notes: group feat PR titles by area label (area/agent-loop, area/skills, etc.)
- The `major version boundary` check: if feat_count > 0 but last_tag starts with v0., allow minor cut (0.x → 0.x+1 is not a major boundary)
- Fail-open on all external API calls

---

## Zone 3 — Scoped out

- §40.4 (curated release notes template) — that's a separate issue (#946)
- Actually generating full release notes (beyond --generate-notes) — deferred to 40.4
- Milestone auto-closing — separate concern
