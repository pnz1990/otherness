# 40: Autonomous Releases — Agents Cut Patch and Minor, Humans Cut Major

> Status: Active | Created: 2026-04-20
> Applies to: all projects managed by otherness

---

## What this does

Releases don't happen because nobody owns the decision of when to cut one. The agent
ships PRs continuously — but without an explicit release mechanism, versions pile up
on `main` untagged while users run stale builds.

This design doc specifies the decision logic for autonomous release cutting:

- **Patch releases** (x.y.Z → x.y.Z+1): cut automatically. Bug fixes, chores, security
  patches. The agent decides when enough has accumulated.
- **Minor releases** (x.Y.0 → x.Y+1.0): cut automatically. New features that don't
  break compatibility. The agent decides based on shipped design doc Present items.
- **Major releases** (X.0.0 → X+1.0.0): **human-initiated only.** Architectural
  changes, breaking API changes, or shifts in what the product fundamentally is. The
  agent surfaces when a major is warranted but does not cut it.

The human's only release job: decide what constitutes a breaking change (once, in
`AGENTS.md` or `otherness-config.yaml`), and cut major versions when they arise.

---

## Release decision logic

### Patch release trigger (SM §4h or PM §5l, runs every 3 cycles)

Cut a patch release when ALL of the following are true:
- Current latest tag is at least 7 days old
- At least 3 PRs merged since the last tag with `fix:`, `security:`, or `chore:` prefix
  and zero `feat:` PRs (if there are feat PRs, this is a minor, not a patch)
- CI on main is green
- No open `[NEEDS HUMAN]` issues

Patch release process:
```bash
LAST_TAG=$(git describe --tags --abbrev=0)
NEXT=$(python3 -c "
parts = '$LAST_TAG'.lstrip('v').split('.')
parts[2] = str(int(parts[2]) + 1)
print('v' + '.'.join(parts))
")
gh release create "$NEXT" --title "$PROJECT_NAME $NEXT" \
  --generate-notes --latest
```

### Minor release trigger (PM §5l, runs every 5 PM cycles)

Cut a minor release when ALL of the following are true:
- Current latest tag is at least 7 days old
- At least 3 PRs merged since the last tag with `feat:` prefix
- At least 1 new `✅ Present` item in any `docs/design/*.md` since last tag
  (confirms the feature is documented, not just implemented)
- CI on main is green
- No open `[NEEDS HUMAN]` issues
- No open feature PRs (in_review items would make this release incomplete)

Minor release process:
```bash
LAST_TAG=$(git describe --tags --abbrev=0)
NEXT=$(python3 -c "
parts = '$LAST_TAG'.lstrip('v').split('.')
parts[1] = str(int(parts[1]) + 1)
parts[2] = '0'
print('v' + '.'.join(parts))
")
# Generate release notes from merged PRs since last tag
gh release create "$NEXT" --title "$PROJECT_NAME $NEXT" \
  --generate-notes --latest
```

### Major release — human only

The agent detects when a major release may be warranted and surfaces it:
- Breaking API changes (CRD schema field removed, CLI flag renamed/removed)
- Architectural pivot (detected by: design doc with "breaking", "incompatible", or
  "migration required" in its title or Zone 3)
- Human explicitly requests via `/otherness.vibe-vision` with "major release" intent

When detected: PM opens an issue labeled `needs-human kind/release priority/high`:
```
[RELEASE] v2.0.0 candidate — human decision required

Reason: <specific breaking change detected>
What shipped since v1.x: <summary of features>
Suggested release notes draft: <attached>

This release requires human approval because it contains breaking changes.
Reply 'cut it' to this issue to proceed, or close to defer.
```

The agent does not cut it. The human decides.

---

## Release notes quality

Generated release notes (`--generate-notes`) use PR titles. For release notes to be
meaningful, PR titles must be semantic (the existing `type(scope): description`
convention enforced by AGENTS.md). The agent adds a curated summary section above the
auto-generated list:

```markdown
## What's in vX.Y.Z

### New features
- <bullet per feat: PR, grouped by design doc area>

### Bug fixes
- <bullet per fix: PR>

### Security
- <bullet per security: PR>

### Upgrading
<any config changes needed — read from AGENTS.md breaking changes section>
```

---

## Config

```yaml
# In otherness-config.yaml
releases:
  enabled: true          # default: true. Set false to disable autonomous releases.
  min_days_between: 7    # minimum days between releases (default: 7)
  major_human_only: true # default: true. MUST NOT be changed to false.
```

---

## Present (✅)

*(Nothing shipped yet.)*

---

## Future (🔲)

- 🔲 40.1 — SM §4h / PM §5l: patch release trigger — 7-day age + ≥3 fix/security/chore PRs + no feat PRs + CI green + no NEEDS HUMAN. Auto-cut patch with `gh release create --generate-notes`.
- 🔲 40.2 — PM §5l: minor release trigger — 7-day age + ≥3 feat PRs + ≥1 new Present item since tag + CI green + no open feature PRs. Auto-cut minor with curated summary section.
- 🔲 40.3 — PM §5l: major release detection — detect breaking API changes or architectural pivots. Open `needs-human kind/release` issue with draft release notes. Never cut autonomously.
- 🔲 40.4 — PM §5l: release notes template — curated summary above `--generate-notes` output. Group feat PRs by design doc area. Include "Upgrading" section from AGENTS.md breaking changes.
- 🔲 40.5 — `otherness-config.yaml`: add `releases:` section with `enabled`, `min_days_between`, `major_human_only` fields. `major_human_only` is read-only — any PR that sets it to `false` is rejected by QA.
- 🔲 40.6 — validate.sh: check that `releases.major_human_only` is not set to `false` in any `otherness-config.yaml` in the repo. Hard fail if found.

---

## Zone 1 — Obligations

**O1 — Major releases are never cut autonomously. No exceptions.**
`releases.major_human_only: true` is enforced by validate.sh (item 40.6). Any
modification to this field triggers the CRITICAL tier gate. Any PR that changes it
to `false` is blocked by QA regardless of AUTONOMOUS_MODE.

**O2 — A release is never cut when CI is red.**
The release trigger checks CI on `main` before creating the release. A red main means
something is broken — releasing it would be wrong.

**O3 — A release is never cut when there are open `[NEEDS HUMAN]` issues.**
An unresolved human escalation means the system is in an uncertain state. Releases
require a known-good baseline.

**O4 — The `min_days_between` floor is respected.**
The agent does not cut a release less than `min_days_between` days after the previous
one, even if the trigger conditions are met. Frequent small releases erode the meaning
of a release. Default: 7 days.

**O5 — Release notes must be accurate.**
The curated summary (item 40.4) must only include features confirmed by ✅ Present
items in design docs. If a feature was merged but has no design doc Present item,
it is not listed in the curated section (it may appear in the auto-generated PR list).

---

## Zone 2 — Implementer's judgment

- Whether to run release logic in SM or PM: PM §5l is better — PM already runs cross-
  project checks and has the right scope. SM runs per-batch; PM runs every N batches.
  Release is a PM concern, not an SM concern.
- Whether to use `--generate-notes` or full manual: hybrid (item 40.4). Auto-generated
  notes are complete but noisy. The curated summary at the top gives humans a quick read.
- The 7-day minimum between releases: this is conservative. Projects shipping fast may
  want 3 days. Projects shipping slowly may want 14. Make it configurable (item 40.5).

---

## Zone 3 — Scoped out

- Pre-release tags (alpha, beta, rc) — complexity not warranted yet
- Changelog file (CHANGELOG.md) — GitHub releases are the changelog
- npm/PyPI/Helm chart publishing — separate per-project concern, not otherness generic
- Rollback automation — separate design doc if needed
