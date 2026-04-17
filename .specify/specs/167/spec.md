# Spec: feat(coord): D4 translation for GitHub issue comments

> Item: 167 | Risk: medium | Size: m | Tier: CRITICAL (coord.md — phases file)

## Design reference
- **Design doc**: `docs/design/02-human-instruction-interpretation.md`
- **Section**: `§ Future (🔲)`
- **Implements**: GitHub issue instructions intercepted (🔲 → ✅)

---

## Zone 1 — Obligations

**O1**: After claiming an item, coord.md must read recent comments on that issue and check for imperative instructions from non-agent humans.
- **Falsified by**: Agent proceeds to Phase 2 without checking for human instructions on the claimed issue.

**O2**: Detected imperative instructions must be translated via D4 (posted as `[📋 D4 TRANSLATION]` on the issue) before the agent acts on them.
- **Falsified by**: Agent acts on an imperative instruction without posting a D4 translation.

**O3**: The check must distinguish agent comments (starting with `[🎯`, `[🔨`, `[🔍`, `[🔄`, `[📋`) from human comments.
- **Falsified by**: An agent comment is treated as a human instruction.

**O4**: If no imperative instructions are found, the check is a no-op (does not block or modify Phase 2 entry).
- **Falsified by**: Coord stalls when no human instructions are present.

**O5**: `docs/design/02-D4.md` `## Future` must be updated: `🔲 GitHub issue instructions intercepted` → `✅ Present`.
- **Falsified by**: Item still in Future after merge.

---

## Zone 2 — Implementer's judgment

- How many recent comments to check: last 5 comments (limits API calls)
- What constitutes an "imperative instruction": any comment from a human containing action verbs like "add", "fix", "update", "change", "make", "create", "remove"
- Whether to wait 60s: yes, same as D4 session-start protocol
- Whether to create a new issue from the translation: post translation on current issue; a new queue item is only created if the human confirms

---

## Zone 3 — Scoped out

- Does NOT monitor all open issues (only the currently claimed item's issue)
- Does NOT block merge if translation is not acted on within this session
- Does NOT check PR comments (only issue comments)
