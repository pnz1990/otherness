# Spec: issue-894 — PM §5l: Major Release Detection (design doc 40.3)

## Design reference
- **Design doc**: `docs/design/40-autonomous-releases.md`
- **Section**: `§ Future`
- **Implements**: 40.3 — PM §5l: major release detection — detect breaking API changes or architectural pivots. Open `needs-human kind/release` issue with draft release notes. Never cut autonomously. (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — PM must detect breaking changes by scanning merged PRs and design doc titles since the last git tag.**
Breaking change signals: PR title contains `!` (breaking change convention), or design doc Future/Zone3 contains "breaking", "incompatible", or "migration required". If none found, no issue is opened.

**O2 — When a breaking change is detected, PM opens one `needs-human kind/release priority/high` issue.**
The issue title must match `[RELEASE] vX.Y.Z candidate — human decision required`.

**O3 — The issue body must include: reason (specific breaking change), what shipped since last tag, and a draft release notes template.**
An issue without all three sections violates this obligation.

**O4 — PM never cuts the major release autonomously.**
No `gh release create` for major releases. The issue is the only output.

**O5 — Deduplication: at most one open major-release-candidate issue at a time.**
Before opening, PM checks for an existing open issue with `[RELEASE]` in title. If found, skip (or post follow-up if >14 days old).

**O6 — Opt-out: if `releases.enabled: false` in otherness-config.yaml, skip entirely.**

---

## Zone 2 — Implementer's judgment

- The breaking change detection heuristic is fuzzy (keyword matching). False positives are acceptable — human review will filter. False negatives (missing a breaking change) are more dangerous. Err toward sensitivity.
- `!` in PR title is the conventional breaking change marker (e.g., `feat!: rename config field`).
- Detection runs once per PM cycle (not every N_PM_CYCLES) because major releases are rare and the check is cheap.
- The `kind/release` label may not exist on fresh repos — the code should not fail if it's missing; fall back to `kind/chore` or just `needs-human`.

---

## Zone 3 — Scoped out

- Actually cutting the major release (human-only)
- Minor and patch release triggers (40.1 already handles patch; 40.2 is separate)
- 40.5 (releases: section in config) — separate issue
- 40.6 (validate.sh check) — separate issue
