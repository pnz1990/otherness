# 20: Command File Sync

> Status: Active | Created: 2026-04-19
> Applies to: all projects managed by otherness

---

## The problem

When otherness adds a new command (`/otherness.vibe-vision`), existing projects never get it. When otherness removes a command (`otherness.cross-agent-monitor`, `otherness.pause`), existing projects keep the stale file forever. Projects set up once silently drift from the current state of `~/.otherness`.

This is a broken user experience. A person using otherness on multiple projects should never have to think about command file management. Commands should always match the installed version of otherness — the same guarantee speckit gives by bundling commands in its binary.

---

## The model: bundle with the tool update

Speckit solves this by packaging commands inside the CLI binary. When you upgrade speckit, the commands update automatically. There is no separate "sync commands" step.

Otherness is a git repo, not a binary. The equivalent guarantee: when `~/.otherness` updates (which happens on every session startup via `git pull`), the project's command files update in the same step. One operation. Zero user action.

---

## The fix: full sync in SELF-UPDATE

The `standalone.md` SELF-UPDATE block already runs `git -C ~/.otherness pull` on every session startup. The fix adds one more step immediately after: **a full two-way sync of `otherness.*.md` command files**.

```bash
# After git -C ~/.otherness pull:

if [ -d ~/.otherness/.opencode/command ] && [ -d .opencode/command ]; then
  SYNCED=0

  # 1. Add or update: copy all otherness.* commands from ~/.otherness
  for src in ~/.otherness/.opencode/command/otherness.*.md; do
    [ -f "$src" ] || continue
    fname=$(basename "$src")
    dest=".opencode/command/$fname"
    # Copy only if content differs (avoids dirtying git state unnecessarily)
    if ! cmp -s "$src" "$dest" 2>/dev/null; then
      cp "$src" "$dest"
      SYNCED=1
    fi
  done

  # 2. Remove stale: delete any otherness.* commands not in ~/.otherness
  for dest in .opencode/command/otherness.*.md; do
    [ -f "$dest" ] || continue
    fname=$(basename "$dest")
    if [ ! -f ~/.otherness/.opencode/command/"$fname" ]; then
      rm "$dest"
      SYNCED=1
    fi
  done

  [ $SYNCED -eq 1 ] && echo "[STANDALONE] Command files synced from ~/.otherness."
fi
```

Two directions. Files added to `~/.otherness` appear in the project. Files removed from `~/.otherness` disappear from the project. Content-diff before copying avoids unnecessary git dirty state.

---

## The naming convention

`otherness.*.md` filenames in `.opencode/command/` are owned by otherness. They sync automatically. Projects that need a custom command should use a non-`otherness.*` filename (`run.md`, `build.md`, etc.) — those are never touched by the sync.

---

## What this fixes immediately

On the next `/otherness.run` (or scheduled run) on any project:
- `otherness.vibe-vision.md` appears ✓
- `otherness.arch-audit.md` appears ✓
- `otherness.onboard.md` appears ✓
- `otherness.cross-agent-monitor.md` disappears ✓
- `otherness.pause.md` disappears ✓

No human action. No re-running setup. No manual file operations.

---

## Present (✅)

*(Not yet implemented.)*

## Future (🔲)

- 🔲 `standalone.md` SELF-UPDATE: add full two-way command sync (add new + remove stale)
- 🔲 `bounded-standalone.md`: same sync step
- 🔲 `.opencode/command/otherness.setup.md` Step 4: change "skip if exists" to "always overwrite + remove stale"
- 🔲 `.github/workflows/otherness-scheduled.yml`: add command sync step after `git clone ~/.otherness` (scheduled runs start from scratch — no .opencode/command/ yet)

---

## Zone 1 — Obligations

**O1 — standalone.md SELF-UPDATE performs a full two-way sync after every pull.**
Add: copy all `otherness.*.md` from `~/.otherness` if content differs. Remove any
`otherness.*.md` in the project that no longer exist in `~/.otherness`.

**O2 — The sync is silent when nothing changed, logs one line when it updates.**
`echo "[STANDALONE] Command files synced from ~/.otherness."` only when at least one
file was added, updated, or removed.

**O3 — Non-`otherness.*` files in `.opencode/command/` are never touched.**

**O4 — The scheduled workflow syncs commands after cloning `~/.otherness`.**
The scheduled runner starts with a fresh checkout that has no `.opencode/command/`
from `~/.otherness`. It must mkdir and copy after the clone step.

**O5 — `/otherness.setup` Step 4 is updated to match this logic.**
The initial setup should also perform the full sync (overwrite + remove stale) rather
than the old "skip if exists" behavior.

---

## Zone 2 — Implementer's judgment

- CRITICAL-A classification: standalone.md adds executable bash (not [AI-STEP] comments).
  5-check self-review. Autonomous merge if all pass.
- Whether to commit the synced files: no. Working tree sync is sufficient.
- Whether to log each file individually: no. One summary line is enough.
- bounded-standalone.md: it wraps standalone.md, so the SELF-UPDATE block there
  needs the same sync step.

---

## Zone 3 — Scoped out

- Syncing non-command files (agents/ syncs globally via git pull, not per-project)
- Two-way sync pushing project customizations back to ~/.otherness
- Versioned command files per project (all projects get the same version as ~/.otherness)

