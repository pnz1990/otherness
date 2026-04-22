# 42: Speckit Integration — Version Tracking and Adoption Policy

> Status: Active | Created: 2026-04-21
> Applies to: otherness itself and all managed projects

---

## What this does

Speckit (spec-kit / specify-cli) is otherness's structured artifact layer. It provides
the `.specify/specs/`, `.specify/memory/`, and `tasks.md` scaffolding that ENG uses to
write verifiable specs before implementation. The version of speckit in use affects session
reliability — bugs in speckit can silently corrupt specs, block non-interactive sessions,
or produce malformed `.specify/memory/` files.

This design doc formalises how otherness tracks speckit releases, what the adoption
criteria are, and specifies the three concrete changes from the 0.7.3/0.7.4 release cycle.

---

## Adoption criteria

A speckit release is worth adopting when it contains at least one of:
1. A fix to non-interactive behaviour (session reliability — affects scheduled runs)
2. A fix to context file parsing (BOM, encoding, marker format — affects spec quality)
3. A new capability that replaces something otherness currently hand-rolls

A speckit release is NOT worth adopting when it only contains:
- New community catalog entries (third-party extensions)
- New presets for unrelated use cases (fiction writing, Salesforce, etc.)
- Academic citation support (CITATION.cff, Zenodo)
- Bug fixes for integrations otherness does not use (Forgecode, Trae, agy)

---

## Present (✅)

- ✅ speckit used for `.specify/specs/$ITEM_ID/spec.md` three-zone structure — ENG §2b (eng.md)
- ✅ speckit used for `.specify/memory/decisions.md` architectural decision log — ENG §2d ⚠️ Stale — referenced file not found
- ✅ speckit used for `.specify/memory/constitution.md` and `sdlc.md` — onboarding docs ⚠️ Stale — referenced file not found
- ✅ speckit version upgraded from 0.7.2 → 0.7.4 (2026-04-21)
- ✅ `SPECKIT_COPILOT_ALLOW_ALL_TOOLS=1` set in scheduled workflow — non-interactive sessions no longer prompt for permissions (2026-04-21)
- ✅ decisions.md writes use marker-based upsert pattern (`specify memory set`) instead of raw `cat >>` — prevents concurrent session corruption (2026-04-21)
- ✅ 42.3 — SM §4a-speckit: speckit release check every 10 SM cycles. Queries `gh api repos/github/spec-kit/releases/latest`, compares against `specify --version`, opens `kind/chore` issue if >1 minor behind AND release body contains reliability/context-parsing keywords ("non-interactive", "BOM", "context", "upsert"). Graceful skip if speckit not installed or API unavailable. Dedup: at most one open speckit update issue. (PR #897, 2026-04-22)

---

## Future (🔲)

- 🔲 42.1 — `scripts/validate.sh`: add check that speckit version installed locally matches the pinned version in `onboarding-new-project.md`. Fails if `specify --version` returns a version older than the pinned one. Prevents "works on my machine" issues when the local speckit is behind the version otherness expects.
- 🔲 42.2 — `otherness-config-template.yaml`: add `speckit.version` field. Projects can pin their own speckit version independently of otherness's local install. The ENG startup block reads this field and runs `uv tool install specify-cli --from git+https://github.com/github/spec-kit.git@<version>` if the installed version differs.
- ✅ 42.3 — see ✅ Present section above. (PR #897, 2026-04-22)
- 🔲 42.4 — `eng.md §2d`: migrate `decisions.md` writes to use `specify memory set "<key>" "<value>"` when speckit ≥ 0.7.3 is available. Fall back to `cat >>` if speckit is absent or older. The marker-based upsert prevents duplicate entries and handles concurrent sessions safely.

---

## Zone 1 — Obligations

**O1 — speckit version is pinned in onboarding docs, not assumed.**
`onboarding-new-project.md` and `onboarding-existing-project.md` must specify an exact
version in the install command (`@v0.7.4` not `@latest`). A floating `@latest` pin means
a breaking speckit release breaks all new project onboardings simultaneously.

**O2 — Non-interactive flag is set for all scheduled sessions.**
`SPECKIT_COPILOT_ALLOW_ALL_TOOLS=1` must be present in the scheduled workflow environment.
Without it, speckit may prompt for permission confirmation in non-interactive mode, blocking
the session indefinitely. This is a correctness requirement, not a convenience.

**O3 — Session reliability fixes are adopted within one release cycle.**
When a speckit release contains a fix tagged "non-interactive", "BOM", "context file",
or "concurrent", otherness must adopt it within 7 days of release. These fixes affect
every scheduled session on every managed project.

**O4 — Community catalog entries are not adopted without explicit human review.**
Extensions from the community catalog (Blueprint, Ripple, Spec Scope, agent-assign, etc.)
affect agent behaviour in ways that may conflict with otherness's own loop. No community
extension is added to any project's speckit install without a human reading its source
and approving it as a D4 item.

---

## Zone 2 — Implementer's judgment

- The `SPECKIT_COPILOT_ALLOW_ALL_TOOLS` env var is the correct key as of 0.7.4.
  The deprecated `SPECKIT_ALLOW_ALL_TOOLS` still works but emits a warning. Use the new key.
- `specify memory set` is available since 0.7.3. For projects running older speckit
  (e.g. managed projects where speckit isn't installed at all), the `cat >>` fallback
  is safe. The condition check is: `specify --version 2>/dev/null | python3 -c "import sys; v=sys.stdin.read().strip(); parts=v.split('.'); print(int(parts[1])>=7 and int(parts[2])>=3)" 2>/dev/null`.
- The SM release check (42.3) should use the GitHub API's `etag` header for conditional
  requests — no-cost if the latest release hasn't changed since last check.

---

## Zone 3 — Scoped out

- Adopting speckit's workflow engine (0.7.0) — we have our own loop
- Adopting the Issues community extension (0.6.2) — otherness's QA already closes issues; the extension duplicates this at lower quality
- Adopting any preset other than the core speckit framework
- Running `specify init` on managed projects automatically — projects may have existing `.specify/` state that `init` would overwrite
