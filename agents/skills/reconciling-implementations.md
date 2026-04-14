# Skill: Reconciling Implementations

Load this skill when reviewing a PR as QA.

Designs are the desired state. Code is the current state. Every judgment below is relative to
what the designs say, not what the code currently does.

**Priority order when tradeoffs are unavoidable:**

```
Correctness > Performance > Observability > Testing > Simplicity
```

The default is no tradeoffs. Code is cheap to produce. Quality is cheap to improve. Do not cut
scope — work through every dimension. When a genuine conflict exists, this ordering decides.

Understand the code before running the checklist. Read the designs, read the implementation,
run the tests, build a mental model. The checklist is a lens for evaluating code you understand,
not a substitute for understanding it.

---

## Correctness

The system converges to the state described by the designs from any starting point.

- [ ] Designs are implemented as stated. Every obligation in the spec is met. No obligation is
      partially met and shipped.
- [ ] No spurious errors on the happy path — every error represents a real failure condition,
      not a defensive check that will never fire.
- [ ] Every error path is handled, propagated, and logged at the outermost level where context
      is richest. Swallowed errors and silent fallbacks are correctness bugs.
- [ ] The system can crash at any line and recover without corrupting persistent state. Writes
      are atomic or idempotent. Partial writes leave state recoverable.
- [ ] Concurrent code is free of data races. Shared mutable state is immutable, copied, or
      synchronized with explicit locking.
- [ ] Think: what correctness risk is not on this list for this specific change?

---

## Performance

Measure and budget runtime cost. Invisible resource consumption compounds.

- [ ] Algorithmic complexity is optimal for the expected input size. O(n²) where O(n) suffices
      is a correctness-class bug at scale.
- [ ] Hot-path allocations are justified. No unnecessary copies, conversions, or intermediate
      allocations in code that runs per-request or per-loop-iteration.
- [ ] End-to-end benchmarks exist for latency-sensitive paths and do not meaningfully regress
      from the baseline.
- [ ] Memory footprint is justified. Only store and copy what is needed for the operation's
      duration. Nothing persists longer than its useful life.
- [ ] Think: what performance risk is not on this list for this specific change?

---

## Observability

The system's runtime behavior is understandable from its outputs.

- [ ] Errors logged at ERROR level, side effects logged at INFO level, debug detail at DEBUG.
      Logged exactly once — not at every layer of the call stack.
- [ ] Log messages are in plain English with structured context (key=value pairs). A person
      reading logs at 3am without prior context can understand what happened and why.
- [ ] Errors compose into readable narratives. Wrapping an error adds context; it does not
      discard the original.
- [ ] Key operational signals have metrics: throughput, error rate, latency for anything that
      will be monitored in production.
- [ ] Think: what observability gap is not on this list for this specific change?

---

## Testing

Integration tests survive refactors. Unit tests don't. Push coverage to the edges.

- [ ] Tests span the system and real dependencies as practically as possible. Unit tests for
      pure logic; integration tests for anything that touches I/O, state, or external calls.
- [ ] Happy path and edge cases both have coverage. Edge cases include: empty input, maximum
      input, concurrent access, missing optional fields, partial failure.
- [ ] Fault injection tests exercise error paths. Every `if err != nil` or `catch` has a test
      that fires it.
- [ ] Bug fixes are accompanied by a regression test named to describe the bug it prevents.
- [ ] Tests do not flake. Assertions observe completion, never sleep-and-hope. Non-determinism
      is seeded or mocked.
- [ ] Test suite runs fast. No unnecessary sleeps, redundant setup, or serial execution where
      parallel execution suffices.
- [ ] **Live-cluster coverage gate**: if this PR implements or modifies a user journey (any
      end-to-end flow described in definition-of-done.md), a fake-client test passing in CI is
      necessary but not sufficient. The journey requires live-cluster evidence to be marked ✅:
      either a `[PDCA AUTOMATED]` CI comment showing PASS with real images, or a
      `[LIVE CLUSTER VALIDATED]` comment with exact commands and terminal output. If no such
      evidence exists for the journey this PR touches, label the gap `MISS` and file a follow-up
      validation issue before approving. Do not mark the journey done in the PR.
- [ ] Think: what testing gap is not on this list for this specific change?

---

## Simplicity

Code's textual surface should not require invisible context to interpret correctly.

- [ ] No dead code or unreachable branches. Code that cannot execute is deleted.
- [ ] Dependencies point from features to primitives, never the reverse. Feature-specific
      packages do not import from each other.
- [ ] Every abstraction earns its existence. No indirection without capability gain. If two
      things can be one thing without losing expressiveness, make them one thing.
- [ ] No duplicated code. Small conceptual differences are unified, not copy-pasted. The
      duplication rule applies to intent, not just text.
- [ ] Types encode constraints. Closed sets use enums. Unimplemented interface fields do not
      exist. Optional values are typed optional, not zero-value ambiguous.
- [ ] Validation is as early as possible. Invalid state is rejected at the boundary — the
      entry point of a function, the parse of a config, the decode of a message.
- [ ] Names are accurate and concise. No stuttering. No misleading verbs. Each concept has
      exactly one name used consistently across every surface — code, logs, docs, error messages.
- [ ] Comments trace decisions to designs. No stale comments. No commented-out code. Comments
      explain why, not what.
- [ ] Think: what simplicity issue is not on this list for this specific change?

---

## Gap Classification (required for every finding)

Label every issue before raising it:

| Label | Meaning | Action |
|---|---|---|
| `WRONG` | Implementation diverges from what the design requires | Fix the code |
| `STALE` | Implementation reveals the design did not anticipate this case | Post `[NEEDS HUMAN]` with the exact design statement, what the code reveals, and what question needs answering |
| `SMELL` | Code works but violates a simplicity or observability principle | Fix the code |
| `MISS` | A case not covered by the design that should have been | Raise as a new issue; do not expand PR scope |

Do not silently choose between conflicting design commitments. Surface `STALE` gaps to the human.

---

## Approval Criteria

**APPROVE** when all Correctness items pass and no WRONG or STALE labels remain.
Performance, Observability, Testing, and Simplicity issues may be raised as follow-up items
if they do not affect correctness — but must be filed as issues before merging, not deferred
silently.

**REQUEST CHANGES** when any Correctness item fails, or when a WRONG or STALE classification
is found. Maximum 3 QA cycles. If unresolved after 3 cycles, escalate to `[NEEDS HUMAN]`.
