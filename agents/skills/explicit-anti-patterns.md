# Skill: Explicit Anti-Patterns

<!-- provenance: BerriAI/litellm, AGENTS.md, 2026-04-14 -->
<!-- otherness-learn: COMMON PITFALLS section format; config-driven flags over hardcoded checks; "when in doubt, follow existing patterns" -->

Load this skill when writing any agent instruction file (standalone.md, onboard.md, skill files)
or when reviewing for completeness — specifically, whether the instruction covers failure modes
the agent is likely to hit.

---

## The COMMON PITFALLS Section <!-- provenance: BerriAI/litellm, AGENTS.md, 2026-04-14 -->

LiteLLM's AGENTS.md ends with a COMMON PITFALLS section that lists recurring mistakes with before/after examples:

```markdown
## COMMON PITFALLS TO AVOID

1. **Breaking Changes**: LiteLLM has many users — avoid breaking existing APIs
4. **UI/Backend Contract Mismatch**: When adding a new entity type, always check whether
   the backend accepts a single value or an array...
8. **Do not hardcode model-specific flags**: Put flags in config and read via helpers...
9. **Never close HTTP clients on cache eviction**: Evicted clients may still be in-flight...
```

Each pitfall has:
- A name (bolded)
- Why it's a pitfall (one sentence)
- What to do instead (or a concrete example)

**The otherness implication:** `standalone.md` has an anti-patterns table in `AGENTS.md`, but it's in the *project context file* — agents don't read AGENTS.md while implementing, they read standalone.md. The agent instruction loop itself should contain a brief COMMON PITFALLS section near the end of the engineer phase.

**Concrete patterns to add to the otherness engineer phase:**

```markdown
## Common pitfalls in this codebase

1. **State to main**: Never `git push origin main` for state changes. Use the canonical
   STATE_MSG + write block. The hard rule is never-breakable.

2. **Worktree dir already exists**: Always check `[ -d "$MY_WORKTREE" ]` before
   `git worktree add`. A stale dir from a crashed session will cause a confusing error.

3. **Hardcoded project names**: Never write `pnz1990`, `alibi`, `kardinal`, or any
   specific project name into standalone.md. It runs on all projects.

4. **`git add .` stages state.json**: If .otherness/state.json was modified while reading
   state, `git add .` will stage it. Always `git add <specific-file>` per the
   ephemeral-pr-artifacts skill.

5. **Forgetting [NEEDS HUMAN] on CRITICAL PRs**: Any PR touching standalone.md or
   bounded-standalone.md must get the needs-human label before the PR is posted.
   Forgetting this is the most common CRITICAL tier violation.
```

This list should be maintained and grown. When a bug is fixed, add the failure mode to the pitfalls list so future sessions don't repeat it.

---

## Config-Driven Flags Over Hardcoded Checks <!-- provenance: BerriAI/litellm, AGENTS.md, 2026-04-14 -->

LiteLLM: "Do not hardcode model-specific flags. Put flags in config files and read via helpers."

```python
# BAD: hardcoded model check
if "claude-3-7-sonnet" in model or "opus-4-5" in model:
    return True

# GOOD: config-driven
if supports_reasoning(model=model, custom_llm_provider=...):
    return True
```

The reason: when a new model adds the capability, the code "just works" — no PR needed.

**The otherness implication:** Behavior flags that differ by project should live in `otherness-config.yaml`, not be hardcoded in standalone.md. Currently:

- CI provider is hardcoded as `github-actions` in several places
- The `14-day` learn schedule threshold is hardcoded in standalone.md (line ~516)
- The `3 retry` and `1s/2s backoff` values in the state write block are hardcoded

**The improvement direction**: These thresholds belong in `otherness-config.yaml` under a `[behavior]` section. standalone.md reads them from config. When a project needs a different CI provider or a 7-day learn schedule, they change config, not the agent file.

**When to act on this**: Currently the hardcoded values are reasonable defaults and the cost of the abstraction isn't earned yet. But as more projects adopt otherness, projects will want different thresholds. Track this in the roadmap.

---

## "When in Doubt, Follow Existing Patterns" <!-- provenance: BerriAI/litellm, AGENTS.md, 2026-04-14 -->

LiteLLM: "When in doubt: follow existing patterns in the codebase."

This is simple but important because it has a corollary: **before writing new code, search for how the same thing was done before.**

For otherness: before writing a new state write, check the existing pattern at the top of standalone.md. Before writing a PR body, check a recent merged PR. Before adding a skill file, check existing skill file structure.

The failure mode this prevents: an agent that writes a novel pattern when an established one exists. Novel patterns fragment the codebase. The reader of standalone.md (another agent) must now understand two ways to do the same thing.

**Concrete check**: Before writing any bash block or Python snippet in an agent file, search standalone.md for an existing block that does the same thing. If one exists: copy it exactly, don't invent a variation.
