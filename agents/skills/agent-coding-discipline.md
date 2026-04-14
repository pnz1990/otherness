# Skill: Agent Coding Discipline

<!-- provenance: forrestchang/andrej-karpathy-skills, CLAUDE.md, 2026-04-14 -->
<!-- otherness-learn: Karpathy's CLAUDE.md; surgical changes and verifiable goals are novel to otherness -->

Load this skill when the engineer is about to write or modify code.

These principles address the most common failure modes in autonomous AI coding:
over-building, over-refactoring, and shipping without verifiable completion criteria.

---

## Surgical Changes <!-- provenance: forrestchang/andrej-karpathy-skills, CLAUDE.md, 2026-04-14 -->

Touch only what the task requires. Clean up only your own mess.

When editing existing code:
- Do not improve adjacent code, comments, or formatting that the task does not require changing.
- Do not refactor things that aren't broken to make them "cleaner."
- Match the existing style, even if you would do it differently in a new file.
- If you notice unrelated dead code or issues, mention them in the PR description — do not fix them in this PR.

When your changes create orphans:
- Remove imports, variables, and functions that **your** changes made unused.
- Do not remove pre-existing dead code unless the task specifically requires it.

**The test:** Every changed line traces directly to the task. A reviewer should be able to read the diff and understand why each line changed without reading the background.

Violations of this principle are the single most common cause of PRs being hard to review, noisy diffs, and accidental regressions in unrelated code.

---

## No Speculative Scope <!-- provenance: forrestchang/andrej-karpathy-skills, CLAUDE.md, 2026-04-14 -->

Write the minimum code that satisfies the spec. Nothing beyond.

- No features beyond what the spec explicitly requires.
- No abstractions for code that has only one call site.
- No "flexibility" or "configurability" that the spec did not request.
- No error handling for scenarios that cannot occur given the spec's constraints.

Ask: "Would a senior engineer reading this diff say it's overcomplicated for what it does?"
If yes, simplify before opening the PR.

The spec is the obligation boundary (see `declaring-designs` skill, Zone 1). Everything beyond the spec is speculation. Speculation introduces bugs and maintenance burden without delivering value.

---

## Verifiable Goals Before Starting <!-- provenance: forrestchang/andrej-karpathy-skills, CLAUDE.md, 2026-04-14 -->

Before writing code, transform the task into a concrete success criterion.

| Vague task | Concrete criterion |
|---|---|
| "Add validation" | "These 5 test cases for invalid input all pass" |
| "Fix the bug" | "Test that reproduces the bug passes; no regression in existing suite" |
| "Refactor X" | "All tests pass before AND after; diff shows no behavior change" |

For multi-step tasks, state a brief plan with a verification step per stage:
```
1. Add type definition → verify: TypeScript compiles
2. Implement handler → verify: unit test passes
3. Wire to router → verify: integration test passes
```

Strong success criteria let the engineer loop independently without human input.
Weak criteria ("make it work") require clarification mid-implementation, which defeats autonomous execution.

This pairs with TDD: the success criterion becomes the failing test.
