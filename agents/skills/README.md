# Skills Index

This directory contains reusable skill files loaded by the agent during the loop.

Skills are **additive only** — never delete content from a skill file (see constitution §IV).

## When to load each skill

| Skill file | Load when | Phase |
|---|---|---|
| `declaring-designs.md` | Writing or evaluating a `spec.md` | Phase 2a (ENG — SPEC-FIRST) |
| `agent-coding-discipline.md` | About to write or modify code | Phase 2d (ENG — TDD) |
| `reconciling-implementations.md` | Reviewing a PR as QA | Phase 3 (QA — ADVERSARIAL REVIEW) |
| `autonomous-workflow-patterns.md` | Designing a multi-step feature or reviewing workflow logic | Phase 2a, 2d, or 3 |
| `role-based-agent-identity.md` | Writing or improving agent instructions (standalone.md, onboard.md) | Phase 4 (SM) or when updating agent files |
| `contribution-hygiene.md` | Opening a PR or writing a commit message | Phase 2f (ENG — before gh pr create) |
| `agent-responsibility.md` | Starting any non-trivial task — before spec, before code, before PR | All phases — load at task start |
| `ephemeral-pr-artifacts.md` | Opening a CRITICAL tier PR or any complex PR needing reviewer context | Phase 2f (ENG — before gh pr create) |

## Skill summaries

### `declaring-designs.md`
Spec quality standard. Defines the three-zone structure (Obligations / Implementer's judgment /
Scoped out), 11 properties every spec must have, gap classification (WRONG / STALE), and the
spec template. Use this to write specs and to evaluate whether an existing spec is good enough
to implement from.

### `agent-coding-discipline.md`
Surgical changes and verifiable goals. Three principles: touch only what the task requires;
write the minimum code that satisfies the spec; define a concrete success criterion before
writing a line. Addresses the most common autonomous coding failure modes: over-building,
over-refactoring, shipping without verifiable completion.

### `reconciling-implementations.md`
QA checklist in priority order: Correctness → Performance → Observability → Testing → Simplicity.
Gap classification: WRONG (fix code), STALE (surface to human), SMELL (fix code), MISS (new issue).
Approval and request-changes criteria. Live-cluster coverage gate for user journeys.

### `autonomous-workflow-patterns.md`
Workflow design patterns from Archon and CrewAI. Transferable to otherness markdown
loops: deterministic vs AI nodes, human approval as first-class gate, context refresh in long
loops, failure handling. Use when designing how a multi-step feature should be broken down.

### `autonomous-workflow-patterns.md`
Workflow design patterns from Archon and CrewAI. Covers: human approval as a named gate vs emergency stop; deterministic vs AI steps; context refresh in long loops; single registry for extension points; autonomy-precision spectrum (crews vs flows); conditional routing on state values. Use when deciding how to structure a multi-step implementation.

### `role-based-agent-identity.md`
Role identity patterns from CrewAI. The role+goal+backstory trinity as a behavior constraint (not just a label). Backstory calibrates agent judgment on ambiguous cases. Roles vs tools vs task contracts. Use when writing or improving agent phase instructions to ensure consistent behavior across diverse inputs.

### `contribution-hygiene.md`
PR and commit discipline patterns from LangChain. Covers: AI disclosure footer required in every AI-opened PR; conventional commit scope enforcement (scope is not optional); PR body should explain why not what; dead code removal before committing. Load before opening any PR or writing commit messages.

### `agent-responsibility.md`
Responsibility and judgment patterns from Pydantic AI. The agent's primary responsibility is to the project and all its users, not the immediate requester. Covers: trust-but-verify research before implementing; alignment before implementation for unclear scope; the how matters as much as the what. Load at the start of any non-trivial task — the most fundamental skill for autonomous agent quality.

### `ephemeral-pr-artifacts.md`
PR operational patterns from OpenHands. Covers: `.pr/` directory for reviewer context that auto-cleans on merge; `git add <file>` over `git add .` for safe autonomous staging; trigger-based skill loading (improvement direction for when skills library exceeds 15 files). Load before opening any complex or CRITICAL tier PR.

## `PROVENANCE.md`
Audit trail of `/otherness.learn` sessions. Records what was learned, from which repo, on what
date, and what was accepted vs rejected. Not a skill — do not load it as one. Read it to
understand what learning has already been done.

## Growing the skills library

New skills are added by running `/otherness.learn` against high-signal open-source repos.
Each new skill must meet the quality gate:
- **Specific**: describes a concrete pattern, not general advice
- **Falsifiable**: a reader can identify behavior that violates the skill
- **Novel**: not already captured in an existing skill
- **Transferable**: applies to otherness on any project, not just the source repo

After adding a new skill, append an entry to `PROVENANCE.md`.
