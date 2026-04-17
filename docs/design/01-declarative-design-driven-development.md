# 01: Declarative Design-Driven Development (DDDD)

> Status: Active | Created: 2026-04-17
> Applies to: all projects managed by otherness

---

## What this does

Every feature the agent implements must be traceable to a **design document that
existed before the spec was written**. Design documents live in `docs/design/` and
describe user-visible behavior, interfaces, and constraints at the feature-area level.
Specs describe a single implementable item within a feature area.

The hierarchy is:

```
docs/aide/vision.md          — what the product is, forever
docs/aide/roadmap.md         — what stages deliver it
docs/design/<N>-<area>.md    — how a feature area works (the design layer)
.specify/specs/<ITEM>/       — how one item within that area is implemented
code                         — the implementation
```

Every layer is a gate for the layer below. You cannot write a spec without a design
doc. You cannot ship code without a spec. After shipping, the design doc is updated to
mark what is present vs future.

---

## Present (✅)

- ✅ Design doc required before spec — ENG creates `docs/design/` file before writing spec.md (PR #144, 2026-04-17)
- ✅ Spec `## Design reference` section required — QA blocks PR if absent (PR #144, 2026-04-17)
- ✅ Design doc updated in same PR as feature — `🔲 → ✅` markers move on merge (PR #144, 2026-04-17)
- ✅ COORD reads design doc Future items as primary queue source — roadmap is fallback (PR #144, 2026-04-17)
- ✅ PM validates design-doc coverage each cycle — opens kind/docs issues for gaps (PR #145, 2026-04-17)
- ✅ Design doc for Stage 5 (Versioned Release Model) — created `docs/design/03-versioned-release.md` (PR #152, 2026-04-17)
- ✅ CI lint for `## Design reference` presence in spec files — validate.sh check 5 (PR #153, 2026-04-17)
- ✅ Customer doc requirement checked by QA — MISS finding (follow-up issue) when non-N/A design ref has no customer doc (PR #159, 2026-04-17)

## Future (🔲)

- 🔲 `/otherness.onboard` generates design doc drafts inferred from codebase — marked ⚠️ Inferred (O7 — deferred: requires onboarding agent update)

---

## Zone 1 — Obligations

**O1 — Design doc must exist before spec.**
Before writing `.specify/specs/ITEM_ID/spec.md`, the ENG phase must identify which
`docs/design/` file covers this feature area. If none exists, ENG creates it before
writing the spec. Creating the design doc is part of the item's work.

**O2 — Spec must reference its design doc.**
Every `spec.md` must contain a `## Design reference` section naming the `docs/design/`
file and the specific section within it that this item implements. QA blocks the PR if
this section is absent.

**O3 — Design doc update ships in the same PR as the feature.**
If the implementation adds, changes, or completes behavior declared in the design doc,
the PR must also update that design doc — marking completed items `✅ Present` and
leaving future items `🔲 Future`. The PR description must list which design doc was
updated.

**O4 — Queue generation reads design docs, not just roadmap.**
When the COORD generates a queue, it reads `docs/design/` to find feature areas with
`🔲 Future` items. These items are the source of truth for what to build next. The
roadmap describes stages; the design docs describe what goes in each stage. Both are
required inputs.

**O5 — PM validates design-doc coverage every N cycles.**
The PM phase checks that every feature area referenced in `docs/aide/roadmap.md` has
a corresponding `docs/design/` file. Missing design docs are opened as `kind/docs`
issues with priority/high before any new implementation work is queued.

**O6 — Customer-facing docs are also design artifacts.**
For user-visible features: `docs/<feature>.md` (the customer doc) must exist before
implementation begins, even if it only contains the interface contract and marks
internals as `🔲 Future`. It is updated in the same PR as the feature. The design doc
and customer doc are distinct: design docs describe how the system works internally;
customer docs describe how a user interacts with it.

**O7 — Onboarding generates design docs, not just aide docs.**
`/otherness.onboard` reads the existing codebase and produces drafts of both
`docs/aide/` and `docs/design/`. The design doc drafts are marked as inferred from
code (`⚠️ Inferred — review before treating as authoritative`).

---

## Zone 2 — Implementer's judgment

- How many design docs are created for a new project: one per major feature area is
  the target. Splitting or merging areas is the ENG agent's call.
- The exact format of `✅ Present` / `🔲 Future` markers within a design doc: inline
  table, checkbox list, or section heading — any is acceptable as long as it is
  machine-parseable by the COORD queue generator.
- Whether the customer doc and the design doc live in the same file or separate files:
  for small features, combining is acceptable. For large areas, separate.
- How to handle design docs that predate this system (no markers yet): treat all
  content as implicitly `✅ Present` until the first DDDD cycle adds explicit markers.

---

## Zone 3 — Scoped out

- Enforcing design doc quality via CI lint (deferred — hard to machine-check prose quality)
- Version history or changelogs within design docs (git log is sufficient)
- Design docs for infrastructure/tooling items (`chore`, `fix`, `refactor` that don't
  add user-visible behavior) — these go directly to spec without a design doc requirement
- Formal design review process or sign-off (the agent is the author and reviewer)

---

## Interfaces

### Design doc structure

```markdown
# <N>: <Feature Area Name>

> Status: Draft | Active | Archived
> Covers: <what roadmap stages this maps to>

## What this does
<One paragraph. What capability does the user gain from this feature area?>

## Present (✅)
<Bulleted list. What is already implemented and shipped.>

## Future (🔲)
<Bulleted list. What is declared but not yet implemented. These are COORD queue inputs.>

## Design

<The actual design content: interfaces, data models, contracts, examples.
 The load-bearing section. Should be the longest.>

## Customer interface
<How a user interacts with this feature area. Commands, UI elements, CRD fields.
 May reference or duplicate docs/<feature>.md.>

## Rejected alternatives
<Why this approach over alternatives.>
```

### Machine-readable Present/Future markers

The COORD queue generator reads design docs looking for `🔲 Future` items. The format
must be parseable:

```
## Future (🔲)
- 🔲 <item description> — <why deferred>
- 🔲 <item description> — <why deferred>
```

Completed items move to Present:

```
## Present (✅)
- ✅ <item description> — <PR #N, date>
```

### Spec `## Design reference` section

```markdown
## Design reference
- **Design doc**: `docs/design/06-kardinal-ui.md`
- **Section**: `§ Enterprise polish`
- **Implements**: keyboard shortcuts (🔲 → ✅)
```

---

## How COORD uses design docs for queue generation

```python
# Queue generation reads BOTH roadmap.md AND docs/design/
# Priority: design doc Future items > roadmap deliverables

import re, os

design_dir = 'docs/design'
future_items = []

for fname in sorted(os.listdir(design_dir)):
    if not fname.endswith('.md'): continue
    content = open(f'{design_dir}/{fname}').read()
    # Find Future section
    m = re.search(r'^## Future.*?\n(.*?)(?=^## |\Z)', content, re.MULTILINE | re.DOTALL)
    if m:
        items = re.findall(r'^- 🔲 (.+)', m.group(1), re.MULTILINE)
        for item in items:
            future_items.append({'source': fname, 'item': item})

# future_items are the primary input to queue generation
# Roadmap deliverables are secondary (catch anything not yet in a design doc)
```

---

## Rejected alternatives

**"Just add stronger instructions to ENG §2c."**
The current §2c is three comment lines. Stronger prose fails for the same reason: the
agent has no structural way to know it violated the constraint. Making design docs a
machine-readable gate (QA checks for `## Design reference`, COORD reads `🔲` items)
creates a feedback loop that doesn't rely on the agent reading and remembering prose.

**"Use the spec as the design doc."**
Specs are item-scoped (one PR, one feature). Design docs are area-scoped (many PRs,
one feature area over time). Collapsing them loses the ability to read the design
state of an area without reading every spec.

**"Keep the current approach and just be more disciplined."**
Discipline degrades under autonomous operation. The model must make the correct
behavior the path of least resistance, not require the agent to remember to do it.
