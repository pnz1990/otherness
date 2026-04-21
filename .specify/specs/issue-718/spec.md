# Spec: onboarding-existing-project.md ongoing loop health check section

## Design reference
- **Design doc**: `docs/design/32-stage-3-onboarding-quality.md`
- **Section**: `§ Future`
- **Implements**: `onboarding-existing-project.md` first-run smoke test section — adds an "Is the loop still working?" section runnable in <5 minutes to confirm ongoing health: (1) `_state` updated in last 24h, (2) ≥1 PR opened/merged in last 7 days, (3) no `[NEEDS HUMAN]` issues older than 48h. (🔲 → ✅)

---

## Zone 1 — Obligations

**O1** — `onboarding-existing-project.md` must contain a section titled "Is the loop still working?" (or equivalent title clearly conveying ongoing health verification, not just first-run).
- Violation: section is absent or only covers first-run (within 20 minutes), not ongoing health (days/weeks later).

**O2** — The section must contain three runnable `bash` commands that check, respectively:
1. `_state` branch updated in last 24h
2. At least one PR opened or merged in last 7 days
3. No `[NEEDS HUMAN]` issues older than 48h
- Violation: any of the three checks is absent, or uses placeholder pseudocode that cannot be run verbatim.

**O3** — Each command must include the expected output (pass condition) as a code comment or inline prose.
- Violation: a command is present but a user cannot tell from the section alone what "passing" looks like.

**O4** — The section must be self-contained: a human must be able to run all three checks without reading any other section of the guide.
- Violation: the section references another step number or relies on a variable defined elsewhere.

**O5** — The section must mention `/otherness.status` as an alternative that covers the same checks in a single command.
- Violation: `/otherness.status` not mentioned.

---

## Zone 2 — Implementer's judgment

- Placement: append the new section immediately after the existing "First-run smoke test" section (after the "Common first-run failures" table), so both check flows are co-located.
- The three commands should use `$REPO` derived from `git remote get-url origin`, similar to the existing smoke test commands, to avoid hardcoding.
- Exact heading wording is at implementer's discretion as long as it communicates "ongoing / not just first-run".

---

## Zone 3 — Scoped out

- Modifying `/otherness.status` output — the issue notes it isn't actionable enough, but that is a separate item.
- Adding automated scheduled health checks — this section is human-runnable only.
- Windows/non-bash instructions.
