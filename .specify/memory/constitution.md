# otherness Constitution

**Version**: 1.0.0 | **Ratified**: 2026-04-14

This document governs all agent behavior when running on the otherness repo. It supersedes all other guidance when there is a conflict.

---

## I. Do No Harm to Other Projects (NON-NEGOTIABLE)

Changes to `agents/standalone.md` or `agents/bounded-standalone.md` deploy immediately to every project using otherness worldwide. These files are CRITICAL tier.

Any PR touching these files MUST post `[NEEDS HUMAN: critical-tier-change]` and MUST NOT be autonomously merged. Post the comment, leave the PR open, and move on to the next item. Do not merge it yourself under any circumstances.

---

## II. The Product Is the Agent Loop

otherness has no UI, no API, no binary. The product is the quality of decisions the standalone agent makes on real projects. Every improvement is measured against: do the managed reference projects advance? Are fewer `[NEEDS HUMAN]` escalations needed per batch?

A feature that looks good in the code but doesn't improve agent behavior on reference projects is not an improvement.

---

## III. Validate Against Reality

The test suite (`scripts/test.sh`) must include a live integration check against a reference project. A passing test suite that doesn't verify the agent actually works on a real project is not a passing test suite.

When the integration check fails (alibi stalled, no recent merges), that is a P0 issue. Stop all other work and investigate.

---

## IV. Skills Are Additive Only

Never remove content from `agents/skills/*.md`. Skills can be extended, corrected, and expanded. They cannot be deleted or replaced without a `[NEEDS HUMAN]` review.

The skills library is the accumulated learning of the system. Deleting from it is deleting memory.

---

## V. Escalate CRITICAL Tier Changes, Never Shortcut

If you believe a change to `standalone.md` or `bounded-standalone.md` is urgent and low-risk — it still requires `[NEEDS HUMAN]`. There are no exceptions. The risk is not the specific change; it is the deployment model. One bad line in `standalone.md` breaks every user simultaneously.

---

## VI. Hunt for Gaps, Don't Confirm Existing Beliefs

The SM and PM phases are not rubber stamps. The SM must find at least one process gap per batch. The PM must find at least one product gap per batch. "Everything looks fine" is not a valid SM or PM report — it means the agent didn't look hard enough.

For otherness specifically: compare against Hermes, Multica, and Archon every batch. Find what they do that otherness doesn't. Open issues.
