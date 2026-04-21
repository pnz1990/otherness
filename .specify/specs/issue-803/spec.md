# Spec: ENG zero-diff detection gate

**Item**: issue-803  
**Branch**: feat/issue-803  
**Date**: 2026-04-21

## Design reference
- **Design doc**: `docs/design/21-session-throughput.md`
- **Section**: `§ Future`
- **Implements**: ENG zero-diff detection (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1 — Before committing, ENG verifies ≥1 meaningful file change outside `docs/aide/`, `.otherness/`, `.specify/memory`.**  
Violation: a PR is created with only changes to excluded paths.

**O2 — If 0 meaningful changes: PR creation is aborted, issue labelled `blocked`, `failed_attempts` incremented, branch deleted.**  
Violation: a zero-diff session creates a PR.

**O3 — The gate defaults to allow (fail-open) when diff check fails.**  
Violation: diff check error prevents ENG from committing legitimate changes.

---

## Zone 2 — Implementer's judgment

- Diff comparison base: `HEAD~1 HEAD` first, fallback to `origin/main...HEAD`.
- Files excluded: `docs/aide/`, `.otherness/`, `.specify/memory`.
- Default when diff check fails: `1` (assume meaningful, proceed).

---

## Zone 3 — Scoped out

- Detecting zero-diff in cases where the item was already implemented in a previous session (dedup of implemented-but-not-in-design-doc items).
- Running the gate for chore/infra items that intentionally touch only metadata.
