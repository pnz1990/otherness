# Skill: Contribution Hygiene

<!-- provenance: langchain-ai/langchain, AGENTS.md, 2026-04-14 -->
<!-- otherness-learn: AI disclosure in PRs; conventional commit scope enforcement; clean PR discipline -->

Load this skill when opening a PR or writing a commit message.

These patterns address the most common PR discipline failures in autonomous AI contributions:
missing context for reviewers, untraceable changes, and stale references.

---

## AI Disclosure in Every PR <!-- provenance: langchain-ai/langchain, AGENTS.md, 2026-04-14 -->

LangChain requires: "Always add a disclaimer to the PR description mentioning how AI agents are involved with the contribution."

This is not optional and not just for transparency — it sets reviewer expectations. A PR opened by an AI agent will have different failure modes than a human PR: the agent may have misread the spec, optimized for the wrong metric, or missed a domain-specific constraint that would be obvious to a human.

**The otherness implication:** Every PR opened by the standalone agent must include a footer:

```markdown
---
*Opened autonomously by [otherness](https://github.com/pnz1990/otherness). Review for correctness — the agent may have missed domain context visible in issue discussion or recent commits.*
```

This is not a warning label — it is a reviewer aid. The human reviewing the PR knows to check: did the agent read the right version of the spec? Did it miss a comment on the issue that changed the requirement?

**Concrete check:** Before `gh pr create`, verify the `--body` argument includes the otherness disclosure footer. If not, add it.

---

## Commit Scope Is Not Optional <!-- provenance: langchain-ai/langchain, AGENTS.md, 2026-04-14 -->

LangChain enforces: "All PR titles should include a scope with no exceptions. For example: `feat(langchain): ...`"

The reason: scopeless commits force reviewers to scan the full diff to understand what area changed. With scopes, the reviewer immediately knows which component to examine.

**The otherness implication:** Commit messages already follow conventional commits (`feat(skills): ...`, `fix(agent-loop): ...`). But the rule must be *enforced*, not just encouraged:

- `feat: add thing` — invalid (no scope)
- `feat(skills): add role-based-agent-identity.md` — valid

**Concrete check when writing commits:**
1. Is the format `type(scope): description`?
2. Does the scope match an actual project area (`agent-loop`, `skills`, `tooling`, `docs`, `onboarding`)?
3. Is the description in lowercase (except proper nouns)?

If any answer is no: fix the commit message before pushing.

---

## PR Description: Why, Not What <!-- provenance: langchain-ai/langchain, AGENTS.md, 2026-04-14 -->

LangChain: "Describe the 'why' of the changes, why the proposed solution is the right one. Limit prose. Highlight areas that require careful review."

The failure mode to prevent: a PR description that summarizes what the diff contains. This is useless — the reviewer can read the diff. What they cannot read from the diff:
- Why this approach was chosen over alternatives
- What the spec said this should do
- Which section of the diff is the risky part

**The otherness implication:** A PR body should contain:
1. **Problem** — what was broken or missing (one sentence, links issue)
2. **Fix** — why this approach is correct (not what it does)
3. **Careful review area** — if one part of the diff is riskier than the rest, say so explicitly
4. **AI disclosure footer** (see above)

What a PR body should NOT contain:
- A restatement of the commit message
- A bullet list of files changed
- "Closes #X" as the only content

---

## Remove Dead Code Before Committing <!-- provenance: langchain-ai/langchain, AGENTS.md, 2026-04-14 -->

LangChain: "Remove unreachable/commented-out code before committing."

This applies with extra force to AI-generated code, where the agent may leave:
- A previous approach as a commented-out block
- A variable that was used in a discarded implementation
- An import that was added then made unnecessary

**The otherness implication (agent-coding-discipline extension):** Before committing, scan the diff for:
- Lines starting with `#` that are commented-out code (not comments about the code)
- Variables declared but never read
- Imports not referenced in the file

If found: remove them before the commit. A reviewer seeing commented-out code in a PR from an AI agent has no way to know if it was intentional or a mistake.
