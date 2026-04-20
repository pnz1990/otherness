# Spec: kro upstream tracking — SM opens anchor-growth issue on version bump

**Item**: issue-528
**Branch**: feat/issue-528

## Design reference

- **Design doc**: `docs/design/26-anchor-kro-ui.md`
- **Section**: `§ Future — kro upstream tracking`
- **Implements**: kro upstream tracking: when kro version bumps, SM opens anchor-growth issue for new API surface (🔲 → ✅)

---

## Zone 1 — Obligations

**O1** — `agents/phases/sm.md` must contain a new section `§4g-anchor-upstream` that reads an upstream version from a configurable file, compares against the last-seen version stored in `_state`, and opens an anchor-growth issue when a version bump is detected.

Violation: Section absent, or version comparison is not performed.

**O2** — The upstream version file and grep pattern must be configurable via `otherness-config.yaml` (`anchor.upstream_version_file` and `anchor.upstream_version_pattern`). If unconfigured, the section must exit gracefully without error.

Violation: Section hardcodes `go.mod` or crashes on projects without the config fields.

**O3** — The opened issue must include the old version, new version, and a request to add anchor coverage for new API surface.

Violation: Issue body is empty or lacks version information.

**O4** — The section must persist the detected version to `_state` as `anchor_upstream_version` to enable future comparisons. Must use the field-level state merge protocol.

Violation: Version not written to `_state`, causing re-triggering on every cycle.

**O5** — Deduplication: if an open issue with "anchor-growth: upstream" in the title already exists, do not open a duplicate.

Violation: Duplicate issues opened on every SM cycle after a version bump.

---

## Zone 2 — Implementer's judgment

- `upstream_version_file` defaults to `go.mod` for Go projects.
- `upstream_version_pattern` defaults to `github.com/awslabs/kro` for kro tracking.
- Runs every SM cycle (not gated on SM_CYCLE count) because version bumps are infrequent.

---

## Zone 3 — Scoped out

- Automatically analyzing what changed in the new version (changelog parsing)
- Multi-upstream tracking (only one upstream per project config)
- Non-semver version tracking
