# Spec: _state branch bootstrap on setup and write

**Issue:** #41
**Size:** S
**Risk tier:** CRITICAL (standalone.md) + HIGH (otherness.setup.md)

## Obligations (Zone 1)

1. After `/otherness.setup` completes, `git ls-remote --heads origin _state` returns a non-empty result for the target repo.

2. The `_state` branch must be an **orphan** (no shared history with `main`). It contains exactly one file: `.otherness/state.json`.

3. If `origin/_state` already exists when `/otherness.setup` runs, Step 6 does nothing and prints "_state branch already exists."

4. The state write block in `standalone.md`, after a failed `git worktree add origin/_state`, must detect the missing branch and bootstrap it before retrying. It must not silently swallow the failure and give up after 3 attempts.

5. The bootstrap in the state write block uses a temporary clone (not the working repo) to avoid interfering with the main worktree's current branch.

6. After bootstrap, the retry loop continues from attempt 0 (not from where it failed).

7. The initial `state.json` written by bootstrap contains the current schema version (`1.3`) and the correct `repo` value read from `git remote get-url origin`.

## Implementer's judgment (Zone 2)

- Whether to use `git checkout --orphan` in the main repo (simpler) or `git clone --no-local` to a temp dir (safer). The temp-clone approach is preferred because it avoids disturbing `HEAD` in the working repo, but either is acceptable if the constraint in Obligation 2 is met.
- The exact wording of log messages.
- Whether to implement the write-block bootstrap as a function or inline.

## Scoped out (Zone 3)

- This spec does not change how state.json is structured or what fields it contains.
- This spec does not fix the `git push origin main` violations (those are in #42).
- This spec does not migrate old state.json schemas (that is #44).

## Interfaces / Schema / Examples

### otherness.setup.md — new Step 6

```bash
## Step 6 — Create _state branch for state persistence

if ! git ls-remote --heads origin _state | grep -q '_state'; then
  echo "Creating _state branch..."
  CURRENT_BRANCH=$(git branch --show-current)
  REPO=$(git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||;s|\.git$||')
  git checkout --orphan _state
  git rm -rf . --quiet 2>/dev/null || true
  mkdir -p .otherness
  python3 - "$REPO" << 'EOF'
import json, sys
repo = sys.argv[1]
state = {"version":"1.3","mode":"standalone","repo":repo,"current_queue":None,
         "features":{},"engineer_slots":{"ENGINEER-1":None,"ENGINEER-2":None,"ENGINEER-3":None},
         "bounded_sessions":{},"session_heartbeats":{"STANDALONE":{"last_seen":None,"cycle":0}},
         "handoff":None}
with open('.otherness/state.json','w') as f: json.dump(state,f,indent=2)
EOF
  git add .otherness/state.json
  git commit -m "state: initialize _state branch"
  git push origin _state
  git checkout "$CURRENT_BRANCH" --quiet
  echo "_state branch created."
else
  echo "_state branch already exists."
fi
```

### standalone.md — state write block bootstrap

Insert before the `for attempt in range(3):` loop:

```python
# Bootstrap _state branch if it doesn't exist
check = subprocess.run(['git','ls-remote','--heads','origin','_state'],
                       capture_output=True, text=True)
if not check.stdout.strip():
    print("State: _state branch missing — bootstrapping...")
    import tempfile, shutil
    boot = tempfile.mkdtemp(prefix='otherness-boot-')
    try:
        r = subprocess.check_output(['git','remote','get-url','origin'],text=True).strip()
        subprocess.run(['git','clone','--no-local','.',boot,'--quiet'], capture_output=True)
        subprocess.run(['git','-C',boot,'checkout','--orphan','_state'], capture_output=True)
        subprocess.run(['git','-C',boot,'rm','-rf','.'], capture_output=True)
        os.makedirs(os.path.join(boot,'.otherness'), exist_ok=True)
        initial = {"version":"1.3","mode":"standalone","repo":r.split('github.com')[-1].strip(':/').rstrip('.git'),
                   "current_queue":None,"features":{},"engineer_slots":{"ENGINEER-1":None,"ENGINEER-2":None,"ENGINEER-3":None},
                   "bounded_sessions":{},"session_heartbeats":{"STANDALONE":{"last_seen":None,"cycle":0}},"handoff":None}
        json.dump(initial, open(os.path.join(boot,'.otherness','state.json'),'w'), indent=2)
        subprocess.run(['git','-C',boot,'add','.otherness/state.json'])
        subprocess.run(['git','-C',boot,'commit','-m','state: initialize _state branch'])
        result = subprocess.run(['git','-C',boot,'push','origin','_state'])
        if result.returncode == 0:
            print("State: _state branch bootstrapped successfully")
        else:
            print("State: bootstrap push failed — state write will continue trying")
    except Exception as e:
        print(f"State: bootstrap error: {e}")
    finally:
        shutil.rmtree(boot, ignore_errors=True)
```

## Verification

```bash
# After implementing:
# 1. Clone a fresh repo, run /otherness.setup
git ls-remote --heads origin _state  # must return a line

# 2. Run /otherness.run once (it will write heartbeat)
git log origin/_state --oneline | head -3  # must show ≥2 commits

# 3. Simulate missing _state: delete the remote branch, run state write block
git push origin --delete _state
# trigger state write → it should bootstrap and write
git ls-remote --heads origin _state  # branch recreated
```

---

## Design reference
- N/A — pre-DDDD item (written before design doc system, PR #144)
