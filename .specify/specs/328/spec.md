# Spec: Two-way command file sync — items 328-331

> Items: 328, 329, 330, 331 | Created: 2026-04-19 | Status: Active

## Design reference
- **Design doc**: `docs/design/20-command-file-sync.md`
- **Implements**: standalone.md + bounded-standalone.md + setup Step 4 + scheduled workflow (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — standalone.md SELF-UPDATE adds two-way command sync after git pull.**
After `git -C ~/.otherness pull`, sync all `otherness.*.md` command files:
add/update from `~/.otherness`, remove stale ones not in `~/.otherness`.
Content-diff before copy. Silent if nothing changed. One log line if anything changed.

**O2 — bounded-standalone.md has the identical sync step.**
Same bash block. Same behavior.

**O3 — `.opencode/command/otherness.setup.md` Step 4 performs the full sync.**
Replace the old "skip if exists" loop with the two-way sync (add + remove stale).

**O4 — `.github/workflows/otherness-scheduled.yml` syncs commands after cloning.**
The scheduled runner starts fresh — it clones `~/.otherness` but the project checkout
already has `.opencode/command/`. After the clone step, run the sync so the runner
uses current command files.

**O5 — Non-`otherness.*` files in `.opencode/command/` are never touched.**

**O6 — Design doc 20 marks all items ✅ Present.**

---

## Zone 2 — Implementer's judgment

- CRITICAL-A: standalone.md and bounded-standalone.md changes add executable bash
  (not [AI-STEP] comments). 5-check self-review. Autonomous merge.
- Setup and workflow changes: LOW tier.
- The sync block is identical in all four places — define once, copy.

---

## Zone 3 — Scoped out

- Committing synced files automatically
- Per-project command customization (different-named files only)
