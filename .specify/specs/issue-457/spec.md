# Spec: hygiene-scan.py standalone script (issue-457)

## Design reference
- **Design doc**: `docs/design/29-continuous-code-hygiene.md`
- **Section**: `§ Future`
- **Implements**: `agents/skills/hygiene-scan.py`: standalone Python script implementing all 5 checks (🔲 → ✅)

## Context

Implements Checks 2-5 from the hygiene design doc. Check 1 and 6 are owned by vibe-vision.
The script is callable directly (`python3 agents/skills/hygiene-scan.py`) or by SM §4g.

---

## Zone 1 — Obligations

**O1 — Implements Check 2 (orphaned TODOs) using git log age detection.**
TODO/FIXME/HACK comments older than 14 days are flagged.

**O2 — Implements Check 3 (dead exports) for dominant language (Python/Go/TypeScript).**
Basic direct-reference check only (not transitive). Flags 0-reference exports as candidates.

**O3 — Implements Check 4 (stale generated files) by checking tracked files vs .gitignore.**
Build artifact patterns from design doc: __pycache__, dist/, .next/, node_modules/

**O4 — Implements Check 5 (docs/design drift) by checking Present item file references.**
Flags when >20% of Present items reference non-existent files.

**O5 — Never modifies or deletes code directly — opens issues only.**
With `--dry-run`, prints findings without opening issues.

**O6 — Cap at `max_issues_per_scan` from config (default 3).**
Reads `otherness-config.yaml hygiene.max_issues_per_scan`.

**O7 — All issues labeled `priority/low`.**
Hygiene items must never preempt higher-priority work.

---

## Zone 2 — Implementer's judgment

- Check 3 only runs for the dominant language (not all languages) to avoid false positives
- Git log age detection for TODOs uses `git log -1 -L` (may be slow on large files — capped)
- Check 4 uses `.gitignore` to avoid false positives on intentionally tracked generated files

---

## Zone 3 — Scoped out

- Check 1 (stale design doc items) — owned by vibe-vision
- Check 6 (stale Future items) — owned by vibe-vision
- Transitive dead code analysis
- Multi-language dead export detection simultaneously
