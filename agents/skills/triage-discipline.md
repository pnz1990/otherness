# Skill: Triage Discipline

<!-- provenance: microsoft/autogen, CONTRIBUTING.md, 2026-04-14 -->
<!-- otherness-learn: weekly triage with explicit per-category responsibilities; awaiting-response tagging; transient CI failure handling -->

Load this skill during Phase 4 (SM — SCRUM MASTER review) to ensure the SM phase is
systematic and complete rather than a cursory pass.

---

## Triage Has Explicit Per-Category Responsibilities <!-- provenance: microsoft/autogen, CONTRIBUTING.md, 2026-04-14 -->

AutoGen formalizes a weekly triage rotation with explicit responsibilities per category:

| Category | SM action |
|---|---|
| Issues with `needs-triage` | Apply labels, assign, reply or escalate |
| PRs ready to merge | Merge if CI passes and approved |
| PRs with transient CI failure | Re-run failed jobs before giving up |
| Discussions needing reply | Reply or assign someone |
| Security alerts | File issues or dismiss |

The key insight: **triage is not "skim GitHub and see if anything looks bad"** — it's a structured checklist run against specific queues.

**The otherness SM phase implication:**

The SM phase currently runs informally — it posts metrics and notes observations. Formalizing it into explicit queues produces more consistent coverage:

```bash
# SM Phase: triage queues to check every batch

# Queue 1: Open PRs
gh pr list --repo $REPO --state open --json number,title,labels,updatedAt \
  --jq '.[] | "#\(.number) \(.title[:60])"'
# → For each: Is it ready? Does it have [NEEDS HUMAN]? Is CI green?

# Queue 2: Open issues without a label
gh issue list --repo $REPO --state open --json number,title,labels \
  --jq '.[] | select(.labels | length == 0) | "#\(.number) \(.title[:60])"'
# → Apply appropriate labels (kind/*, area/*, priority/*)

# Queue 3: Issues awaiting response > 7 days
gh issue list --repo $REPO --state open --json number,updatedAt,title \
  --jq '.[] | select(.updatedAt < (now - 604800 | todate)) | "#\(.number) \(.title[:60])"'
# → Either reply, escalate, or tag with awaiting-response

# Queue 4: PRs with failed CI (possible transient failure)
gh pr list --repo $REPO --state open --json number,title \
  --jq '.[] | "#\(.number) \(.title[:60])"' | while read pr; do
    # check if latest run failed — re-run if possibly transient
  done
```

**The "transient CI failure" rule:** If a CI check failed but no code changed since the last green run, retry before filing a bug. Network flakes, rate limits, and test ordering issues cause real transient failures. Do not escalate or file bugs for first-failure on otherwise green PRs.

---

## Awaiting Response Tagging <!-- provenance: microsoft/autogen, CONTRIBUTING.md, 2026-04-14 -->

AutoGen uses an `awaiting-op-response` label that is **auto-removed when the original poster replies**.

For otherness, the equivalent is the `needs-human` label — but it has no auto-removal. This creates a stale-label problem: items stay `needs-human` long after the human has provided input.

**SM action to add:** After reviewing each `needs-human` issue, check: did the human respond after the label was applied? If yes and the blocker is resolved, remove the `needs-human` label and either close the issue or re-queue the work item.

```bash
# Check needs-human issues for resolved blockers
gh issue list --repo $REPO --state open --label "needs-human" \
  --json number,title,updatedAt,comments \
  --jq '.[] | "#\(.number) last_updated=\(.updatedAt[:10]) \(.title[:50])"'
# For each: read the comments. If the human replied and the blocker is addressed:
# gh issue edit <number> --remove-label "needs-human"
```

---

## Breaking Change Detection in Versioning <!-- provenance: microsoft/autogen, CONTRIBUTING.md, 2026-04-14 -->

AutoGen: "Increase minor version upon breaking changes; increase patch version upon new features or bug fixes."

**The otherness implication:** standalone.md is not versioned, but it effectively has a public interface: the state.json schema, the command file invocation patterns, and the phase structure. When these change in a breaking way (field renamed, command syntax changed), it's equivalent to a minor version bump — all running sessions need to be aware.

**Current gap:** otherness has no changelog for standalone.md changes. Users of otherness on other projects receive the changes via `git pull` on next startup, but there's no signal about what changed.

**Improvement direction (not blocking):** Add a `CHANGELOG.md` to `~/.otherness/agents/` that tracks breaking changes to the agent interface. Each CRITICAL tier PR that changes the state schema or phase structure should add a changelog entry. When `git pull` runs on startup, the agent could check for recent changelog entries and log them.

This is a low-priority improvement — the current silent self-update is fine for the project's current scale. Track for when otherness is used on >10 projects.
