# Spec: Layer 1 D4 ENFORCEMENT section in AGENTS.md template

> Item: 262 | Created: 2026-04-18 | Status: Active

## Design reference
- **Design doc**: `docs/design/07-d4-enforcement.md`
- **Section**: `Layer 1 — AGENTS.md project guard`
- **Implements**: Layer 1: add `## D4 ENFORCEMENT` section to `AGENTS.md` template (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — `otherness-config-template.yaml` includes a `d4_enforcement` config key.**
The config template must add a commented `d4_enforcement: true` entry under the `maqa`
section, documenting that D4 zone enforcement is enabled by default.

Behavior that violates this: config template has no `d4_enforcement` key.

**O2 — `onboarding-new-project.md` generates a `## D4 ENFORCEMENT` section in the target project's AGENTS.md.**
The new-project onboarding document must include an instruction to write the
`## D4 ENFORCEMENT` section to the project's AGENTS.md after setup. The section format
is exactly as specified in design doc 07 Layer 1:

```markdown
## D4 ENFORCEMENT

This project enforces D4. Agents may only act within their declared mode.

| Zone | Permitted by |
|---|---|
| CODE (implementation) | /otherness.run only |
| DOCS (vision/design) | /otherness.vibe-vision only |
| Everything else | READ-ONLY |

Any agent that attempts to act outside its mode must stop and print:
  [🚫 D4 GATE] <zone> writes require <command>. Current session: <mode>.
```

Behavior that violates this: new-project onboarding does not generate the D4 ENFORCEMENT
section in the target AGENTS.md.

**O3 — Design doc 07 marks Layer 1 as ✅ Present.**
`docs/design/07-d4-enforcement.md` must move Layer 1 from 🔲 Future to ✅ Present
in this PR.

Behavior that violates this: doc 07 still shows Layer 1 as 🔲 after this PR merges.

---

## Zone 2 — Implementer's judgment

- Where exactly to add in config template: after the `autonomous_mode` key in the `maqa`
  section, with a comment explaining what it does.
- Whether to modify the repo's own AGENTS.md: NO — `AGENTS.md` is listed in "Files Agents
  Must Not Modify". The D4 ENFORCEMENT section is for managed projects, not the otherness
  repo itself.
- Whether to modify `otherness.setup.md` or `agents/onboard.md`: add to
  `onboarding-new-project.md` since that's the new-project pathway documentation.
  `agents/onboard.md` handles existing projects — add there too if appropriate.

---

## Zone 3 — Scoped out

- Adding `## D4 ENFORCEMENT` to the otherness repo's own `AGENTS.md` (protected file)
- Retroactively adding the section to existing managed projects
- Validating that managed projects have the section (that's Layer 2's job via guard.sh)
