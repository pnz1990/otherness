# Spec: issue-872 — SM health comment skills_count and last-learn date

## Design reference
- **Design doc**: `docs/design/31-stage-2-skills-expansion.md`
- **Section**: `§ Future`
- **Implements**: skills_count and PROVENANCE.md last-learn date published in SM health comment every batch (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

**O1**: SM §4f must compute `skills_count` (count of `*.md` files in `agents/skills/`
excluding `README.md` and `PROVENANCE.md`) and include it in the health comment.

*Falsified by*: health comment posts without a "Skills:" line.

**O2**: SM §4f must read the last learn date from `~/.otherness/agents/skills/PROVENANCE.md`
(most recent `## YYYY-MM-DD` header) and include it in the health comment.

*Falsified by*: health comment posts without a "last learn:" date.

**O3**: The learn date must be color-coded in the comment:
- green if <14 days ago
- amber if 14–30 days ago
- red if >30 days ago

*Falsified by*: date appears without color indicator.

**O4**: If `PROVENANCE.md` cannot be read (missing file, no date entries),
the health comment must show "last learn: unknown" — not error or skip the field.

*Falsified by*: SM fails or omits the learn date field when PROVENANCE.md is missing.

**O5**: The check must be fail-open — errors computing skills_count or reading
PROVENANCE.md must not block the health comment from posting.

*Falsified by*: health comment not posted due to exception in skills/learn computation.

---

## Zone 2 — Implementer's judgment

- Insert the skills/learn computation in SM §4f just before the health comment body
  is assembled. The fields should appear in the health comment under a "Learning:"
  section or appended to the existing Q3 blocking check section.
- Color coding via emoji: 🟢 / 🟡 / 🔴 prefix on the learn date.
- Stagnation check (`skills_count` unchanged from 20 batches ago) is OPTIONAL in this
  PR — the primary obligation is just showing the count and date.

---

## Zone 3 — Scoped out

- Does NOT open issues for stagnation (that is a separate design doc item).
- Does NOT change the health signal GREEN/AMBER/RED logic.
- Does NOT read metrics.md for the 20-batch stagnation check.
