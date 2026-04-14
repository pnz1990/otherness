# State Write Race Condition — Retry with Backoff

## What this does

The state write block in `standalone.md` pushes `state.json` to the `_state` branch. When two
parallel sessions push simultaneously, one push will fail with a non-fast-forward error. The
block must retry with backoff rather than fall back to `main` (which violates the hard rule).

## Obligations (Zone 1)

- On `git push origin _state` exit non-zero: the block fetches `origin/_state`, merges the
  remote state into the local state file (keeping the local changes), and retries the push.
- Retry up to 3 times total (1 initial attempt + 2 retries).
- Backoff between retries: 1 second before retry 1, 2 seconds before retry 2.
- If all 3 attempts fail: log a warning with the error, and return without writing state.
  Execution continues — state loss on heartbeat writes is acceptable; state loss on item
  claims is unfortunate but not catastrophic (the branch-push lock is the real claim).
- The fallback-to-main `except` block is removed entirely. State never goes to `main`.
- The success path is unchanged: a successful push prints `"State written to _state: {msg}"`.

## Implementer's judgment (Zone 2)

- Merge strategy for conflict: last-writer-wins on the specific keys the current session wrote,
  preserve all other keys from the remote. The simplest correct implementation is: fetch remote
  state as a dict, overlay local changes on top, re-write and retry.
- The retry loop may be implemented as a Python `for` loop or `while` with counter.
- The exact log format for the warning message.

## Scoped out (Zone 3)

- This spec does not change how item claims work (the branch-push is the real lock).
- This spec does not add distributed transactions or CAS operations.
- This spec does not address the case where `_state` branch doesn't exist (already handled by
  the existing worktree creation logic).

## Interfaces / Schema / Examples

### Current (broken) state write block — except clause:

```python
except Exception as e:
    print(f"Warning: state write failed ({e}) — falling back to main")
    subprocess.run(['git','add','.otherness/state.json'])
    subprocess.run(['git','commit','-m',f'state: {os.environ.get("STATE_MSG","update")}'])
    subprocess.run(['git','push','origin','main'])   # ← violates hard rule
```

### New state write block — retry loop replacing the except clause:

```python
import subprocess, json, os, tempfile, time

def write_state(state, msg):
    state_wt = os.path.join(tempfile.gettempdir(), 'otherness-state-' + str(os.getpid()))
    for attempt in range(3):
        try:
            subprocess.run(['git','worktree','add',state_wt,'origin/_state','--no-checkout'],
                           capture_output=True, check=True)
            subprocess.run(['git','-C',state_wt,'checkout','_state','--','.otherness/state.json'],
                           capture_output=True)
            # Merge: load remote state, overlay local changes
            remote_path = os.path.join(state_wt,'.otherness','state.json')
            os.makedirs(os.path.dirname(remote_path), exist_ok=True)
            try:
                remote = json.load(open(remote_path))
                remote.update(state)   # local wins on conflict
                merged = remote
            except Exception:
                merged = state
            json.dump(merged, open(remote_path,'w'), indent=2)
            subprocess.run(['git','-C',state_wt,'add','.otherness/state.json'])
            commit_result = subprocess.run(
                ['git','-C',state_wt,'commit','-m',f'state: {msg}'], capture_output=True)
            if commit_result.returncode != 0:
                print("State unchanged (nothing to commit)")
                return
            push_result = subprocess.run(
                ['git','-C',state_wt,'push','origin','_state'], capture_output=True)
            if push_result.returncode == 0:
                print(f"State written to _state: {msg}")
                return
            # Push failed — conflict. Clean up worktree and retry.
            print(f"State push conflict (attempt {attempt+1}/3) — retrying...")
        except Exception as e:
            print(f"State write error (attempt {attempt+1}/3): {e}")
        finally:
            subprocess.run(['git','worktree','remove',state_wt,'--force'], capture_output=True)
        if attempt < 2:
            time.sleep(2 ** attempt)   # 1s, 2s
    print(f"Warning: state write failed after 3 attempts — {msg} lost. Execution continues.")
```

### Verification

- Run two parallel state-write calls with conflicting content and verify both eventually
  succeed (or at most one fails gracefully without touching main).
- `git log origin/_state` shows no commits to `main` with `state:` prefix.

## Rejected alternatives

**Keep fallback-to-main**: Violates the hard rule. State on main creates merge conflicts for
code PRs. Rejected.

**Use file locking**: Not available across git worktrees on different machines. Git push
atomicity is the correct distributed lock. Rejected.

**Three separate functions**: One function with a retry loop is sufficient. No single-caller
abstractions needed. Rejected.
