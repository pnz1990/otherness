# Recovery Guide

If something goes wrong with the autonomous agent, this guide shows how to stop it, clean up, and start fresh. You don't need to understand the code — just follow the steps for your situation.

---

## Situation 1: I want the agent to stop after finishing what it's doing

Create a file called `.otherness/stop-after-current` in your project directory:

```bash
touch .otherness/stop-after-current
```

The agent will finish its current work item, post a final report, and exit. The next time you run `/otherness.run` it will pick up from where it left off.

---

## Situation 2: I want the agent to stop immediately

Just close the OpenCode window. The agent will stop mid-task. The current work item will be left in `assigned` state — the next session will detect the stale assignment and skip it, picking a different item.

If you want to clean up the abandoned item before restarting:

```bash
# 1. Close any open PR for the item (if one was created)
gh pr list --repo <owner/repo> --json number,headRefName \
  --jq '.[] | "#\(.number) \(.headRefName)"'
# Close the PR manually, then delete the branch

# 2. Clean up the local worktree
git worktree list                          # find the stale worktree
git worktree remove ../<repo>.<item-id> --force
git worktree prune

# 3. Mark the item as todo again in state.json (optional — the agent will skip it anyway)
```

---

## Situation 3: The agent created a bad PR or bad issues

**Bad PR**: Just close it on GitHub. The agent checks for existing open issues before creating new ones, but it does not check for closed PRs. Delete the branch too:

```bash
gh pr close <number> --repo <owner/repo>
gh api -X DELETE "repos/<owner/repo>/git/refs/heads/<branch-name>"
```

**Bad issues**: Just close them on GitHub. The agent's duplicate check covers open+closed issues, so it won't re-create them.

---

## Situation 4: The agent is posting `[NEEDS HUMAN]` and not doing anything

This means the agent hit something it couldn't resolve autonomously. Check:

```bash
gh issue list --repo <owner/repo> --state open --label needs-human \
  --json number,title --jq '.[] | "#\(.number) \(.title)"'
```

For each issue: read it, resolve the underlying problem (usually a CI failure or a design question), then close the issue. The agent will resume on the next session.

---

## Situation 5: State.json is corrupt or stuck

Signs: the agent keeps trying to work on the same item, or throws a JSON error at startup.

**Reset state for a single item** (mark it back to todo):

```bash
python3 - << 'EOF'
import json
with open('.otherness/state.json') as f:
    s = json.load(f)

# Replace ITEM-ID with the actual item identifier
item = 'ITEM-ID'
if item in s.get('features', {}):
    s['features'][item]['state'] = 'todo'
    s['features'][item]['assigned_to'] = None
    s['features'][item]['branch'] = None
    s['features'][item]['worktree'] = None

with open('.otherness/state.json', 'w') as f:
    json.dump(s, f, indent=2)
print("Reset done")
EOF

# Then push to _state branch
export STATE_MSG="manual reset"
# (run the state write block from standalone.md, or push directly:)
python3 - << 'EOF'
import subprocess, json, os, tempfile, shutil
state = json.load(open('.otherness/state.json'))
wt = os.path.join(tempfile.gettempdir(), 'otherness-state-fix')
subprocess.run(['git','worktree','add','--no-checkout',wt,'origin/_state'], capture_output=True)
os.makedirs(os.path.join(wt,'.otherness'), exist_ok=True)
json.dump(state, open(os.path.join(wt,'.otherness','state.json'),'w'), indent=2)
subprocess.run(['git','-C',wt,'add','.otherness/state.json'])
subprocess.run(['git','-C',wt,'commit','-m','manual state reset'])
subprocess.run(['git','-C',wt,'push','origin','HEAD:_state'])
shutil.rmtree(wt, ignore_errors=True)
subprocess.run(['git','worktree','prune'])
print("State pushed to _state branch")
EOF
```

**Full state reset** (wipe everything and start fresh):

```bash
# Delete _state branch on remote and re-run setup
gh api -X DELETE "repos/<owner/repo>/git/refs/heads/_state"
/otherness.setup
```

After setup runs, the next `/otherness.run` will re-seed state.json from your merged PR history.

---

## Situation 6: Orphaned worktrees are accumulating

Worktrees are created at `../<repo>.<item-id>/` alongside your main repo directory. If a session crashes, they can accumulate.

```bash
# See what's there
git worktree list

# Remove a specific one
git worktree remove ../<repo>.<item-id> --force

# Remove all that git considers stale
git worktree prune
```

---

## Situation 7: I want to completely remove otherness from a project

```bash
# 1. Delete state
gh api -X DELETE "repos/<owner/repo>/git/refs/heads/_state"
rm -rf .otherness/

# 2. Delete command files
rm .opencode/command/otherness.*.md

# 3. Delete config
rm otherness-config.yaml

# 4. Delete docs (optional — these are useful docs even without the agent)
rm -rf docs/aide/
```

---

## Quick reference

| What happened | Fix |
|---|---|
| Want graceful stop | `touch .otherness/stop-after-current` |
| Hard stop | Close OpenCode window |
| Bad PR | Close and delete branch on GitHub |
| Bad issues | Close them on GitHub |
| Agent stuck on `[NEEDS HUMAN]` | Read the issue, fix the root cause, close it |
| State JSON corrupt | Delete `_state` branch, re-run `/otherness.setup` |
| Orphaned worktrees | `git worktree prune` |
