# 39: Autonomous README Refresh — Agents Keep READMEs Current

> Status: Active | Created: 2026-04-20
> Applies to: all projects managed by otherness

---

## What this does

A project's README is the first thing a new contributor, evaluator, or user reads.
Within weeks of setup it goes stale: features ship that aren't mentioned, the quickstart
references commands that changed, the architecture section describes what the project
*was* not what it *is*.

The existing PM §5i README/AGENTS.md claims cross-check verifies that specific
machine-checkable claims are still true (command files exist, package paths exist).
That is a linter. This design doc specifies a *writer* — an agent that rewrites the
README when it has drifted beyond a staleness threshold, using the current
`docs/aide/vision.md`, `docs/aide/roadmap.md`, and merged PR history as the source
of truth.

**Not a linter. A writer.**

The agent reads what the project actually is today and produces a README that reflects
that reality. It does not patch individual stale claims — it regenerates the
human-facing sections from current D4 artifacts.

---

## What "stale README" means

A README is stale when any of the following is true:
- Last modified >30 days ago AND ≥5 features have shipped since (merged PRs with `feat:` prefix)
- README describes a capability that no longer exists (file/command/field referenced is gone)
- README's quickstart references a workflow that has changed (e.g. still says PAT-only auth after GitHub App was added)
- README's feature list omits a shipped major feature from `docs/design/` Present items

Staleness is computed by the PM phase, not a human.

---

## The refresh mechanism

PM §5k (new step, runs every 10 PM cycles):

```
1. Compute staleness score
   - Days since README last modified (git log -- README.md)
   - Count of feat: PRs merged since README was last modified
   - Count of design doc Present items not mentioned in README (keyword match)
   - Count of commands in README that no longer exist as .opencode/command/ files
   Score = days_stale/30 + feat_prs_since/5 + missing_present/3 + missing_commands*2
   Threshold: score >= 2.0 triggers refresh

2. Build context for the rewrite
   - Read docs/aide/vision.md (what the project is)
   - Read docs/aide/roadmap.md (where it is in the journey)
   - Read docs/aide/definition-of-done.md (what "working" means)
   - Read last 30 merged feat: PR titles (what shipped recently)
   - Read all ✅ Present items from docs/design/*.md (capabilities that exist)
   - Read current README.md (preserve structure, update content)

3. Generate updated README
   [AI-STEP] Rewrite README.md using the context above. Rules:
   - Preserve the project's voice and structure
   - Update the "what it does" section to match current vision.md
   - Update the feature list to include all ✅ Present items from design docs
   - Update the quickstart to match current actual commands
   - Remove references to capabilities that no longer exist
   - Do not add capabilities that aren't in ✅ Present items
   - Keep it concise — a README is not a design doc

4. Open PR
   Title: "docs(readme): refresh — reflects v<N> capabilities and current quickstart"
   Body: staleness score, what changed, design doc Present items added
   Label: kind/docs, priority/low, size/s
```

---

## Present (✅)

*(Nothing shipped yet.)*

---

## Future (🔲)

- 🔲 39.1 — PM §5k: staleness score computation — days since modified, feat PRs since, missing Present items, missing commands. Threshold: score ≥ 2.0.
- 🔲 39.2 — PM §5k: README refresh AI step — rewrite using vision.md, roadmap.md, Present items, recent PR titles as context. Preserve structure, update content.
- 🔲 39.3 — PM §5k: open README refresh PR with staleness score in body, labeled `kind/docs priority/low size/s`.
- 🔲 39.4 — PM §5k: duplicate suppression — check for open README refresh PR before creating another. At most one open at a time.
- 🔲 39.5 — validate.sh check: README last-modified date recorded in a comment at top of README (e.g. `<!-- last-refreshed: 2026-04-20 -->`). validate.sh fails if no such comment exists and README is >90 days old.

---

## Zone 1 — Obligations

**O1 — The refresh rewrites from D4 artifacts, not from the existing README.**
The source of truth is `docs/aide/vision.md` and `docs/design/*.md` Present items.
The existing README is reference material for preserving structure — it is not the
authority on what the project does.

**O2 — The refresh never invents capabilities.**
Only `✅ Present` items in design docs may be added to the feature list. A feature
that shipped but has no design doc Present item is not added — that's a documentation
debt issue (design doc 04), not a README issue.

**O3 — At most one open README refresh PR at a time.**
PM checks for an existing open README refresh PR before creating a new one. If one
exists and is >7 days old without being merged, PM comments on it asking why.

**O4 — A human may opt out per-project.**
Setting `pm.readme_refresh: false` in `otherness-config.yaml` disables §5k for that
project. The human's README is authoritative; the agent does not touch it.

---

## Zone 2 — Implementer's judgment

- Staleness score threshold of 2.0 is calibrated for a typical hourly-shipping project.
  Adjust if the project ships slowly — a threshold that triggers on every 5th PR is too
  aggressive for a project that ships one PR per week.
- The AI rewrite step is the most expensive part. Run it only when staleness is confirmed
  (step 1 first, AI step only if threshold exceeded). Don't generate context and call the
  LLM just to decide not to refresh.
- README structure preservation: identify sections by heading text (H2/H3), rewrite
  section bodies, do not reorder sections. A human who has customised the README order
  should not find it scrambled after a refresh.

---

## Zone 3 — Scoped out

- Refreshing AGENTS.md (too high risk — prompt injection surface)
- Refreshing docs/aide/vision.md (human-authored, never agent-modified)
- Multi-language README support
- README translation
