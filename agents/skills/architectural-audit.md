# Skill: Architectural Audit

<!-- provenance: pnz1990/kardinal-promoter, session 2026-04-15 -->
<!-- otherness-learn: Extracted from a live deep-architecture review of kardinal-promoter
     against krocodile 745998f. The session found 11 distinct issues across false
     documentation claims, redundant abstractions, missing reactivity wiring, and
     design/implementation drift — none caught by CI or PR review. The process that
     found them is generalizable and should be a first-class otherness command. -->

Load this skill when running `/arch-audit`. It defines the methodology for a thorough,
adversarial architecture review of any codebase — checking what is claimed against what
is true, what the underlying primitives now enable that the design hasn't adopted, and
what redundancy or drift has accumulated.

---

## What an Architectural Audit Is

An audit is not a code review. A code review checks if a specific change is correct. An audit
checks if the **whole system's structure** is still the right structure — whether the
decisions made months ago still hold, whether dependencies have grown new capabilities that
make existing complexity unnecessary, whether documented claims are true.

The output is a set of GitHub issues and documentation corrections, not code changes. Code
changes are downstream work that the issues authorize. The audit itself produces only findings.

---

## The Adversarial Stance

The most important property of an audit is that it does not assume anything is correct.
Every claim is checked against source. Every abstraction is questioned. Every "we can't do X"
is verified against whether X is still impossible.

This is the concrete failure the audit exists to prevent: a design claim is accepted and
propagated into docs, roadmap, and agent context — where it causes future agents to build on
a false foundation. The kardinal flat-DAG-compilation idea survived for months before being
examined. The `schedule.isWeekend()` claim survived for weeks. Both were false. Both required
only reading the source code to disprove.

**Default posture**: everything is potentially wrong until verified. "The docs say X" is
not evidence that X is true. "The tech debt doc says this was fixed" is not evidence it was
fixed. Read the actual code.

---

## The Four Audit Lenses

Every finding fits into one of these four categories. Use them to structure the output.

### Lens 1: Documentation/Reality Drift

The documentation says X. The code does something else.

This is the most common and most dangerous finding type. Agents and humans both use docs to
make decisions. False docs produce false decisions.

**How to find these:**
- Read every architectural claim in AGENTS.md, design docs, and tech debt trackers
- For each claim, read the actual code at the cited location
- Verify: is the claim literally true as stated?
- Common drift patterns:
  - "This was eliminated" but the code still has it
  - "This is a library function" but it's actually a map injection
  - "Dependency X handles Y" but X is bypassed
  - "Status: RESOLVED" but the fix is not implemented
  - "No external calls on hot path" but the reconciler calls the API directly

**Output format:**
```
FINDING: [what the doc claims] vs [what the code actually does]
IMPACT: [who is misled and how]
ACTION: fix the doc OR fix the code (specify which)
ISSUE: #N
```

### Lens 2: Unused Primitive / Missed Capability

A dependency has a capability that would simplify or replace existing complexity. The codebase
hasn't adopted it — either because the capability didn't exist when the code was written, or
because no one evaluated it.

This is especially common when underlying platforms evolve fast (e.g., krocodile adding
Definition nodes, forEach, Decorator, WatchKind incremental cache). The project pins a version,
ships features using workarounds, and then the workaround accumulates as "the way things are
done" even after the primitive that makes it unnecessary has landed.

**How to find these:**
- For each external dependency, read its latest changelog/design docs since the current pin
- For each workaround in the tech debt tracker, check: does the dependency now have a native solution?
- Ask: what does each component do that its underlying primitives now do for free?
- Common patterns to look for:
  - Go computation that a CEL expression would handle
  - Polling loops that watch events could replace
  - Redundant filtering that the underlying engine now supports natively
  - Manual resource management that an owned-node reconciler would handle better

**Output format:**
```
FINDING: [primitive X has capability Y that our code re-implements as Z]
WHAT CHANGES: [describe the refactor at a level of specificity sufficient to implement]
CONSTRAINT CHECK: [verify the primitive actually handles our use case — do not assume]
ISSUE: #N
```

### Lens 3: Structural Redundancy / Accumulated Tech Debt

The code does the same thing in two places. A field in a CRD carries information the
underlying engine already guarantees. A safety check duplicates a guarantee already enforced
at a higher layer.

Redundancy is not neutral. It creates maintenance burden (both copies must be kept consistent),
confusion (which one is authoritative?), and often subtle bugs (the two copies drift).

**How to find these:**
- For each field in every CRD: who writes it, who reads it, is the writer redundant?
- For each reconciler check: is the same check also enforced at the Graph/engine layer?
- For each Go computation in a translator/builder: is this already expressed in the spec?
- Pattern: "belt and suspenders" — two guards on the same invariant, one in Go, one in the engine

**Output format:**
```
FINDING: [thing A and thing B both enforce invariant X; A is redundant given B]
WHY DANGEROUS: [how the redundancy causes confusion or divergence]
CORRECT MODEL: [which one should be removed and why]
ISSUE: #N
```

### Lens 4: Missing Reactivity

A component depends on another component's state, but there is no watch/trigger wiring that
makes the dependency reactive. Instead, the dependency is read at a point-in-time (at creation,
at first reconcile, baked into a spec as a literal string). If the source changes, the
dependent is not notified.

This produces systems that are "correct at creation time" but stale in steady state.

**How to find these:**
- For each reconciler: what does it read? Does it have a Watch on every object it reads?
- For each translated/generated spec: are data values baked as literals or live CEL references?
- For each "created once" resource: what happens if its inputs change after creation?
- SetupWithManager is the canonical place to check — what Watches are registered?

**Output format:**
```
FINDING: [component X reads Y at creation time but has no Watch on Y]
SCENARIO: [concrete example of how this causes stale state]
FIX: [add Watch in SetupWithManager + re-queue handler OR change to CEL reference]
ISSUE: #N
```

---

## Audit Execution Protocol

### Step 0 — Scope declaration

Before reading any code, declare what you're auditing:
- Which dependencies will you check for new capabilities?
- Which design docs / AGENTS.md sections will you verify against source?
- Which CRDs / reconcilers will you examine for reactivity?

Write this down. Do not expand scope mid-audit without noting it. An audit that expands
endlessly produces noise. An audit with declared scope produces actionable findings.

### Step 1 — Read the primitives (not the application code)

Read the underlying platform/library from HEAD, not your pinned version. Focus on:
- What new primitives have been added since your pin?
- What existing primitives have been changed in semantics?
- What capabilities were not available when you last evaluated them?

Do not start reading the application code yet. Build a model of what is *now possible*.

### Step 2 — Read the authoritative claims

Read every document that makes architectural claims:
- AGENTS.md
- Design docs (docs/design/)
- Tech debt tracker
- Any "status: RESOLVED" items in the tracker

For each claim, note: what is it asserting? You will verify these against source in Step 3.

### Step 3 — Verify claims against source

For each claim from Step 2, go to the exact source location and verify it. Do not read
broadly — read surgically. The question is always: "Is the claim literally true as stated?"

Track: confirmed / drift / false.

### Step 4 — Apply the four lenses

With the primitive landscape (Step 1) and the claim inventory (Step 2/3) in hand, apply each
lens systematically:

1. **Documentation/Reality Drift** — which claims from Step 3 are false?
2. **Unused Primitive** — which new primitives (Step 1) could replace existing complexity?
3. **Structural Redundancy** — where does the code duplicate what the engine guarantees?
4. **Missing Reactivity** — where is state read at creation time but not watched reactively?

### Step 5 — Triage findings by impact

Not every finding warrants immediate action. For each finding, assess:
- **Correctness risk**: does this produce wrong behavior today?
- **Documentation risk**: does this mislead agents or humans making decisions?
- **Scale risk**: does this become worse as the system grows?
- **Reversibility**: how hard is this to fix later vs now?

Priority:
- HIGH: correctness risk OR actively misleads decision-makers (docs/agents)
- MEDIUM: scale risk OR structural — accumulates over time
- LOW: improvements — valid but not urgent

### Step 6 — Open issues for every finding

Every finding gets a GitHub issue. No exceptions. Findings not in issues are forgotten.

Issue structure:
```
## Finding
[what was found — specific, concrete]

## Why it matters
[correctness/documentation/scale/reversibility impact]

## What correct looks like
[the target state — specific enough to implement]

## Constraint check
[if the finding proposes using a primitive, verify it actually handles the use case]
```

Label every issue with:
- `kind/bug` for correctness findings (Lens 1 drift, Lens 4 reactivity gaps)
- `kind/enhancement` for unused primitive and redundancy findings
- `kind/docs` for pure documentation fixes
- `priority/high`, `priority/medium`, `priority/low`

### Step 7 — Fix documentation immediately

Unlike code changes (which go through PR review), documentation corrections that fix false
claims should be fixed immediately in the same session:

1. Fix the false claim in-place
2. If AGENTS.md is affected, update it (but respect the "files agents must not modify" constraint
   — some projects protect AGENTS.md; check first)
3. Open the audit findings as a PR with all doc fixes together
4. The code changes implied by the findings are separate PRs, filed as issues

---

## Scope Calibration — What to Audit

### Always audit

- Every claim in AGENTS.md that references a specific function, file, or behavior
- Every "status: RESOLVED" item in the tech debt tracker
- Every dependency upgrade changelog since the last pin (using the upgrade protocol)
- The reconciler `SetupWithManager` for every CRD that another CRD depends on

### Audit when the dependency has a major release or N commits ahead

- All design docs that reference the dependency's capabilities
- All workarounds in the tech debt tracker that were filed as "blocked on dependency"

### Audit periodically (every 10 PRs or on milestone boundaries)

- CRD fields: who writes each field, who reads it, is any field orphaned or redundant?
- Go code in translators/builders: is any computation expressible as a CEL reference in the output spec?
- Reconciler reactivity: does each reconciler Watch everything it reads?

### Skip

- Internal naming and code style (that is QA's job)
- Test coverage (that is QA's job)
- Performance micro-optimization without a documented bottleneck

---

## Common False Positives (findings to discard)

**"This could be a CEL expression"** — only valid if the primitive actually supports the
use case in the current version. Verify before filing. "Could" without verification is noise.

**"This is documented as fixed but the comment is still there"** — stale comments are smell
but not architecture findings. File as a SMELL in QA, not as an audit finding.

**"This is duplicated"** — only valid if the duplication has a clear owner problem. Two
implementations of the same function with different callers is duplication. Two safety checks
at different layers on the same invariant where removing one changes the security model is not.

**"The tech debt doc says X is a problem"** — this is not a finding. The finding is whether
X is still a problem after the stated fix, or whether X is now solvable with new primitives.

---

## Output Artifacts

An audit produces exactly three things:

1. **GitHub issues** — one per finding, with labels and priority
2. **Documentation PR** — fixes all false claims found; references the issues
3. **Audit summary comment on the project's report issue** — what was audited, what was found,
   what was filed

Nothing else. No "in-progress refactors" opened as PRs in the same session. No code changes.
The audit authorizes work; it does not do the work.
