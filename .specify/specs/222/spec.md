# Spec: add ## MODE block to every agent file (#222)

## Design reference
- **Design doc**: `docs/design/07-d4-enforcement.md`
- **Section**: Layer 0 — Agent MODE DECLARATION
- **Implements**: 🔲 Layer 0: add ## MODE block to every agent file (🔲→✅)

## Zone 1 — Obligations

**O1** — Every agent file in `agents/` has a `## MODE` block as its first section
after the frontmatter.

Falsifiable: `grep -L "^## MODE" agents/*.md agents/phases/*.md` → empty (all files have it).

**O2** — MODE assignments are correct per design doc 07:
- `standalone.md`, `bounded-standalone.md` → `IMPLEMENT`
- `vibe-vision.md` → `VISION`
- All others → `READ-ONLY`

Falsifiable: grep confirms each file's MODE matches its correct assignment.

**O3** — Each MODE block contains the redirect message naming the correct command.

Falsifiable: each MODE block contains `[🚫 D4 GATE]` text.

**O4** — `validate.sh` check 6 verifies every agent file has a MODE block.

Falsifiable: `bash scripts/validate.sh` passes; deliberately removing a MODE block
causes it to fail.

## Zone 2 — Implementer's judgment
- MODE block goes after frontmatter `---`, before SELF-UPDATE section.
- Redirect messages are concise — 3–4 lines max.
- validate.sh check uses grep pattern `^## MODE:` on agents/*.md and phases/*.md.

## Zone 3 — Scoped out
- guard.sh integration (Layer 2) — that is #223
- Enforcing the MODE at bash-execution level — that requires guard.sh
- Modifying skills/*.md files — skills are not agents
