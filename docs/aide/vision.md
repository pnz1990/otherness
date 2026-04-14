# otherness: Vision

> Created: 2026-04-14 | Status: Active

## What otherness is

otherness is an autonomous software development system. One session is an entire team. It reads a project's `AGENTS.md`, `docs/aide/`, and `state.json`, then loops autonomously: it coordinates work, writes and tests code, adversarially reviews its own PRs, acts as scrum master, acts as product manager, and ships releases — all without human input except for rare `[NEEDS HUMAN]` escalations.

The human's role: define the vision, read the batch reports on the report issue, unblock `[NEEDS HUMAN]` items. Nothing else.

## Why otherness exists

Every AI coding tool that existed before otherness assists a human. The human still owns the loop: they decide what to build next, review every PR, trigger releases, run retrospectives. The AI is a tool in a human process.

otherness eliminates the human from the execution loop entirely. The human defines intent. The system executes. This is not an incremental improvement on "AI-assisted development" — it is a different model of software delivery.

## The self-improvement goal

otherness is now running on itself. This closes the loop: the system that builds software is itself built by that same system. Every improvement to otherness — a better QA checklist, a sharper spec quality standard, a new skill learned from open-source — deploys to every project using otherness on their next session startup.

The target: otherness improves itself faster than humans can improve it manually.

## Current state

- Core loop (`standalone.md`): stable, battle-tested on kardinal-promoter and alibi
- Skills system: 4 skills, growing via `/otherness.learn`
- Self-improvement: enabled as of 2026-04-14
- Known limitation: global deployment model (Option A) — a CRITICAL tier regression affects all users immediately. Mitigated by human review gate on CRITICAL files. Future Option B (versioned releases) documented in AGENTS.md.

## What "done" looks like for otherness

otherness is never done. It is a living system that improves continuously. The benchmark for "good enough to stop manually maintaining" is:

1. otherness ships at least one improvement to itself per week without human prompting
2. The alibi and kardinal-promoter reference projects continue advancing without human intervention
3. `/otherness.learn` discovers and internalizes at least one new pattern per month autonomously
4. The PM validation scenarios all pass: reference projects are alive, skills are growing, docs match behavior

## Design decisions that will not change

1. **Markdown instructions, not code.** The agents are `.md` files. OpenCode runs them. No compiled binary, no server, no database. This makes otherness hackable by anyone with a text editor, and deployable by a `git clone`.

2. **GitHub as the only external system.** All coordination, state, progress reporting, and delivery goes through GitHub. No Slack, no Jira, no custom dashboard. If it's not in GitHub, it doesn't exist.

3. **`~/.otherness` as a shared global install.** Every project on a machine shares the same agent files. Self-update (`git pull`) is the deployment mechanism. Simple to operate, fast to update.

4. **Branch-push as the distributed lock.** Parallel sessions don't collide because git's server-side ref update is atomic. No coordinator needed. No lock file. No heartbeat election.

5. **State on `_state` branch.** Code PRs go to `main`. State changes go to `_state`. This prevents merge conflicts between parallel sessions doing code work and state writes simultaneously.
