# 20: Command File Sync

> Status: Active | Created: 2026-04-19
> Applies to: all projects managed by otherness

---

## The problem

When otherness adds a new command (like `/otherness.vibe-vision`), existing projects
never receive it. The initial `/otherness.setup` copies command files with
`if [ ! -f "$dest" ]` — a "skip if exists" policy that prevents overwriting
customizations. But it also means new commands added to `~/.otherness` after initial
setup are silently absent from every existing project.

The symptom: a project set up before `/otherness.vibe-vision` was added will never
have that command available, unless the operator manually re-runs setup or copies the
file by hand.

---

## The fix: sync on every session startup

Command files in `.opencode/command/otherness.*.md` are not project-customized files.
They are otherness infrastructure — the same across all projects, updated when otherness
updates. They should be treated the same as `~/.otherness/agents/` files: pulled from
the source on every session startup.

The SELF-UPDATE block in `standalone.md` already runs `git -C ~/.otherness pull` on
every startup. Immediately after, it should sync command files from `~/.otherness`
into `.opencode/command/`.

### The sync rule

```bash
# After git -C ~/.otherness pull:
# Sync all otherness command files from ~/.otherness into this project's .opencode/command/
if [ -d ~/.otherness/.opencode/command ]; then
  mkdir -p .opencode/command
  for src in ~/.otherness/.opencode/command/otherness.*.md; do
    fname=$(basename "$src")
    dest=".opencode/command/$fname"
    # Always overwrite — these are infrastructure files, not project customizations.
    # If a project needs a custom version, it should use a non-otherness.* filename.
    cp "$src" "$dest"
  done
  echo "[STANDALONE] Command files synced from ~/.otherness"
fi
```

### The naming convention

`otherness.*.md` filenames in `.opencode/command/` are owned by otherness. They are
always overwritten on sync. Projects that need a custom version of a command should
use a different filename (e.g. `run.md` instead of `otherness.run.md`).

Non-otherness command files in `.opencode/command/` are never touched by the sync.

---

## What this means for existing projects

On the next `/otherness.run` (or scheduled run), the SELF-UPDATE block runs the sync.
All missing commands appear. All outdated commands update. The human does nothing.

---

## What this means for `/otherness.upgrade`

The upgrade command shows version information and helps with pinning. It should also
explicitly mention command sync — reassuring the operator that commands are
automatically kept current. No additional action needed in upgrade for this.

---

## Present (✅)

*(Not yet implemented.)*

## Future (🔲)

- 🔲 `standalone.md` SELF-UPDATE: add command file sync step after `git -C ~/.otherness pull`
- 🔲 `bounded-standalone.md`: same sync step
- 🔲 `/otherness.upgrade`: add note that command files are auto-synced on session startup
- 🔲 `/otherness.setup`: change copy logic from "skip if exists" to "always overwrite otherness.* files"

---

## Zone 1 — Obligations

**O1 — standalone.md SELF-UPDATE syncs command files on every startup.**
After `git -C ~/.otherness pull`, all `otherness.*.md` files from
`~/.otherness/.opencode/command/` are copied to `.opencode/command/` in the project.
Existing files are overwritten. Non-otherness files are never touched.

**O2 — The sync is silent on success, logged on failure.**
`echo "[STANDALONE] Command files synced"` only if files were actually updated.
No output if nothing changed.

**O3 — `/otherness.setup` Step 4 changes from "skip if exists" to "always overwrite".**
The initial setup should also always install the latest version of each command,
not skip if an older version is present.

**O4 — Projects can customize commands using non-`otherness.*` filenames.**
This is the convention that preserves project autonomy while enabling automatic sync.

---

## Zone 2 — Implementer's judgment

- Whether to diff before copying (avoid unnecessary file changes triggering git dirty state):
  copy only if content differs. Use `cmp -s "$src" "$dest" || cp "$src" "$dest"` pattern.
- Whether to commit the updated command files automatically: no. The session works with
  the files in the working tree. If the operator wants to commit them, they can. The
  files are in `.gitignore` or tracked — either way the sync works.
- CRITICAL-A or CRITICAL-B for standalone.md change: the sync adds one executable
  bash block (not an [AI-STEP] comment). CRITICAL-A. 5-check self-review before merge.

---

## Zone 3 — Scoped out

- Syncing non-command files from ~/.otherness into projects (agents/ are already
  global via git pull, not per-project copies)
- Two-way sync (projects never push back to ~/.otherness)
- Versioned command files (all projects get the same version as ~/.otherness)
