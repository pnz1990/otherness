# Spec: Mandatory Spec Conformance Check (#121)

## Zone 1 — Obligations (falsifiable)

### O1: Missing spec is a WRONG finding
If `spec.md` does not exist at `$MY_WORKTREE/.specify/specs/$ITEM_ID/spec.md`, QA must emit a
WRONG finding and not approve the PR.
- **Violation**: QA approves a PR that has no spec.md.

### O2: Spec conformance check before code review
QA must complete the spec conformance check (verify every Zone 1 obligation) before reading
the code diff for quality issues.
- **Violation**: QA approves with code quality checks but no conformance check.

### O3: Hard rule in standalone.md
`standalone.md` HARD RULES must explicitly state that spec conformance check is mandatory.
- **Violation**: `grep -c "spec.*conformance|conformance.*check|zone.*1.*obligation" agents/standalone.md` returns 0.

### O4: Acceptance test passes
```bash
grep -c "spec.*conformance" ~/.otherness/agents/standalone.md  # ≥ 1
```

---

## Zone 2 — Implementer's judgment

- Exact wording of the WRONG message when spec is missing.
- Whether to also check `bounded-standalone.md` (not needed — it delegates to standalone.md).

---

## Zone 3 — Scoped out

- Enforcing three-zone structure quality programmatically (too hard to validate statically).
- Auto-generating spec.md (that's ENG's job).
- Enforcing spec on non-otherness projects using otherness (they may not use speckit).
