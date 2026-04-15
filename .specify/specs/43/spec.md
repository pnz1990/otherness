# Spec: queue generation protocol

**Issue:** #43
**Size:** M
**Risk tier:** CRITICAL (standalone.md)

## Obligations (Zone 1)

1. Phase 1b in `standalone.md` must specify **how** to read `docs/aide/roadmap.md` to derive queue items: identify the current stage (first stage with incomplete deliverables), list its incomplete deliverables, and create one GitHub issue per deliverable that does not already have an open or recently-merged PR.

2. Phase 1b must specify **item size rules**: every generated item must be `size/s` or smaller. If a deliverable cannot fit in `size/s`, the agent must split it and create only the first step.

3. Phase 1b must specify **queue size limit**: generate 3–5 items maximum per generation cycle. Stop and write state. Generate more when the queue runs dry.

4. Phase 1b must specify **the duplicate check**: before creating an item, search open issues and recently-merged PRs (last 20) for the same deliverable. If found, skip.

5. Phase 1b must specify **the acceptance criterion rule**: every generated item must include a single falsifiable acceptance criterion — a bash command or observable state that is true when the item is complete.

6. Items are written to state.json **only after** their GitHub issue is created. The issue number becomes the item ID.

7. The agent must post a `[COORD] Queue generated: N items` comment on `$REPORT_ISSUE` listing each item's issue number and title.

## Implementer's judgment (Zone 2)

- The exact bash/python used to parse roadmap.md stages.
- Whether to check `docs/aide/definition-of-done.md` failing journeys as a secondary input.
- The exact format of the `[COORD] Queue generated` comment.

## Scoped out (Zone 3)

- This spec does not change what a "done" item looks like in state.json.
- This spec does not change how the agent claims items (Phase 1c).
- This spec does not generate items from PM/SM observations (those remain informal).

## Interfaces

### The phase 1b instruction in standalone.md (replaces current 2 lines)

```
1b. If queue null or empty: generate next queue (3–5 items).

    INPUTS:
    - docs/aide/roadmap.md — find current stage (first with incomplete deliverables)
    - docs/aide/definition-of-done.md — find failing journeys
    - Recent merged PRs (last 20) — skip deliverables already done

    DUPLICATE CHECK:
    gh issue list --repo $REPO --state open --json number,title | 
      check if the deliverable already has an issue

    FOR EACH deliverable (max 5 total):
      1. Is it covered by a recently-merged PR? → skip
      2. Is there already an open issue for it? → add to state, skip creation
      3. Otherwise: create GitHub issue with:
         - title: type(scope): specific one-sentence description
         - body: one-paragraph context + acceptance criterion
         - labels: otherness, kind/*, area/*, priority/*, size/s (or size/xs)
      4. Add to state.json: {state: todo, issue: <number>, title: ..., size: ...}

    SIZE RULE: every item must be size/xs or size/s.
    If a deliverable needs more: create only "step 1 of N: ..." as the item.

    ACCEPTANCE CRITERION: every item body must end with:
    ## Acceptance
    <one bash command or observable state that is true when done>

    After generating: post [COORD] Queue generated on $REPORT_ISSUE.
```

### Example well-formed item

```
Title: fix(tooling): otherness.setup.md missing _state branch creation — Step 1 of 2
Body:
  After running /otherness.setup on a new project, the agent cannot persist state
  because origin/_state doesn't exist. This creates the branch during setup.

  See #41 for root cause analysis.

  ## Acceptance
  git ls-remote --heads origin _state | grep -q _state && echo PASS || echo FAIL
  # Must print PASS after /otherness.setup runs

Labels: otherness, kind/bug, area/tooling, priority/critical, size/s
```

## Verification

After this PR merges, trigger a queue generation and verify:
1. Each generated item has a GitHub issue number.
2. Each item's issue body contains an `## Acceptance` section with a runnable command.
3. No generated item is labeled `size/m` or larger.
4. No generated item duplicates an open issue or recent merged PR title.
5. Queue has ≤ 5 items.
