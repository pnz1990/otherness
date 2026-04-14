# Skill: Declaring Designs

Load this skill when writing or evaluating a `spec.md` file.

A design is a story of how the system works. Humans change designs. Agents reconcile
implementations toward them. The design is the human's control surface.

---

## The Three Zones

Every concern in a design falls into exactly one of three zones. Make all three explicit.

**Zone 1 — Obligations.** What the design says must be true. The implementation must satisfy
these. They are falsifiable: a reader can point to concrete behavior that would violate them.

**Zone 2 — Implementer's judgment.** What the design doesn't say, within scope. These choices
can change between implementation passes without the product changing. Name them explicitly so
the implementer knows they have latitude.

**Zone 3 — Scoped out.** What this design deliberately does not cover. Name these too — a
reader who expects a concern to be addressed should find it either committed to, delegated, or
explicitly excluded.

---

## Eleven Properties

Apply these as a checklist to every spec before starting implementation.

**1. Stands alone.**
The design does not describe changes from previous state ("previously we did X, now we do Y").
It does not reference the current implementation ("the existing function at line 47"). It reads
as if the current implementation does not exist.

**2. Consistent.**
No two statements in the design contradict each other. No statement contradicts another design
in the project. When apparent tension exists, it is resolved explicitly.

**3. Every abstraction earns its existence.**
Nothing can be deleted or collapsed without losing capability. If two things could be one thing
without losing expressiveness, they should be one thing. Every interface, type, module boundary,
and named concept justifies its presence.

**4. Boundaries are explicit and falsifiable.**
Every concern a reader would expect is either committed to, delegated to another design, or
explicitly scoped out. Each commitment can be violated concretely — if you cannot describe
behavior that would break a commitment, the commitment is not a commitment.

**5. Every element contributes.**
Every section, example, diagram, and list item is present because removing it would weaken the
design. Nothing repeats. No element is decorative.

**6. Names improve intuitive understanding.**
A reader encountering a name for the first time should correctly guess its purpose. Names are
accurate, concise, and consistent with the project's existing vocabulary. No stuttering
(SessionState not SessionSessionState). No misleading verbs.

**7. Concepts are introduced before they are referenced.**
No forward references. A reader who reads linearly arrives at each new term before it is used
in a sentence that depends on understanding it.

**8. Concrete artifacts carry the design.**
Interfaces, schemas, examples, pseudocode, and type definitions are the load-bearing content.
Prose orients the reader between them. The ratio of artifacts to prose should favor artifacts.
A spec that is 90% prose is a spec that has not been thought through.

**9. Factual claims are verified.**
No "X is generally faster" without a benchmark. No "users typically do Y" without evidence.
Claims under genuine uncertainty are marked as such: "we expect" not "X does".

**10. Rejected alternatives appear at the end.**
Document why the chosen approach was preferred over alternatives the reader might suggest. This
prevents re-litigating settled decisions and shows the design space was explored.

**11. Every word has weight.**
Apply the deletion test: remove the sentence. Does the design change? If not, delete it. No
dramatic language ("this is crucial"). No filler ("it is worth noting"). No defensive framing
("this is a real scenario"). State things once, precisely.

---

## Gap Classification

When the implementation diverges from a design, classify the gap before acting:

- **Implementation is wrong** — the design is correct, the code must change. Fix the code.
- **Design is stale** — the implementation reveals something the design did not anticipate. The
  design must be updated. Surface this to the human with a `[NEEDS HUMAN]` comment explaining
  exactly what the design says, what the implementation reveals, and what question needs answering.

Do not silently prioritize one design commitment over another when they conflict. Surface the
tension explicitly.

---

## Spec Template

Every `spec.md` must contain these sections:

```markdown
# <Feature Name>

## What this does
<One paragraph. Concrete. What capability does the user gain?>

## Obligations (Zone 1)
<Bulleted list. Each item is falsifiable — a reader can describe behavior that violates it.>

## Implementer's judgment (Zone 2)
<What choices are deliberately left to the implementer. Name them so they know they have latitude.>

## Scoped out (Zone 3)
<What this spec explicitly does not cover. At least one entry required.>

## Interfaces / Schema / Examples
<The load-bearing content. Concrete artifacts. This section should be the longest.>

## Rejected alternatives
<Why we chose this approach over alternatives. Optional if there were no real alternatives.>
```
