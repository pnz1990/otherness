# Spec: issue-890 — Phase-role cognitive diversity

## Design reference
- **Design doc**: `docs/design/31-stage-2-skills-expansion.md`
- **Section**: `§ Future`
- **Implements**: Phase-role cognitive diversity (🔲 → ✅)

## Zone 1 — Obligations (falsifiable)

O1. `agents/phases/coord.md` MUST contain a `Cognitive stance:` line in the phase header
    that identifies COORD's frame as "optimistic incrementalist".
    Violation: coord.md has no `Cognitive stance:` line after merge.

O2. `agents/phases/pm.md` MUST contain a `Cognitive stance:` line in the phase header
    that identifies PM's frame as "customer advocate / strategic skeptic".
    Violation: pm.md has no `Cognitive stance:` line after merge.

O3. The preamble text for each phase must name the phase's conflicting stance vs. other phases.
    Violation: preamble says only "X" without stating what it opposes.

O4. `scripts/validate.sh` check [9/9] MUST pass with no WARN for coord.md after merge.
    Violation: `bash scripts/validate.sh` emits "[WARN] phases/coord.md: missing".

O5. The preambles for eng.md, qa.md, sm.md MUST NOT be modified — they already have stances.
    Violation: cognitive stance lines in those files differ from pre-merge content.

O6. Each preamble MUST include a design reference comment linking to issue-890 / design doc.
    Violation: no `<!-- Design ref: ... -->` comment near the Cognitive stance line.

## Zone 2 — Implementer's judgment

- Exact wording of the stance description (within the intent described in issue-890)
- Whether to use `**Cognitive stance: ...**` or plain `Cognitive stance: ...`
- Positioning within the role-identity paragraph (immediately after or as a standalone line)
- Whether pm.md stance merges with or sits below the existing role identity text

## Zone 3 — Scoped out

- Changes to eng.md, qa.md, sm.md (already have stances)
- Adding cognitive diversity tests to validate.sh (validate already checks for the pattern)
- Changing the *content* of existing stances
- Updating README or customer docs (no user-visible behavior change)
