# Spec: scripts/guard.sh — Layer 2 D4 pre-flight zone check (#223)

## Design reference
- **Design doc**: `docs/design/07-d4-enforcement.md`
- **Section**: Layer 2 — Pre-flight check script
- **Implements**: 🔲 Layer 2: scripts/guard.sh (🔲→✅)

## Zone 1 — Obligations

**O1** — `scripts/guard.sh <MODE> <FILE_PATH>` exits 0 if the write is permitted,
exits 1 with a redirect message if blocked.

Falsifiable: `bash scripts/guard.sh READ-ONLY foo.py` exits 1 and prints `[🚫 D4 GATE]`.
`bash scripts/guard.sh IMPLEMENT src/foo.py` exits 0.
`bash scripts/guard.sh IMPLEMENT docs/design/foo.md` exits 1.
`bash scripts/guard.sh VISION docs/design/foo.md` exits 0.
`bash scripts/guard.sh VISION src/foo.py` exits 1.

**O2** — The redirect message names the correct command for the zone.

**O3** — The script is executable and works with bash 3.2+ (macOS default).

**O4** — Design doc 07 marks Layer 2 as Present.

## Zone 2 — Implementer's judgment
- DOCS zone = any path matching `^docs/`
- CODE zone = everything else
- Unknown MODE exits 1 (fail safe)

## Zone 3 — Scoped out
- Wiring guard.sh into agent bash blocks — that is a follow-on task
- guard-ci.sh (Layer 3) — that is #224
