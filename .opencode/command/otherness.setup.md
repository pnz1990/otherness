---
description: "One-time setup: creates otherness-config.yaml and deploys the otherness command files. Run once per project."
---

You are setting up otherness for this project.

## Step 1 — Create otherness-config.yaml if missing

```bash
if [ ! -f "otherness-config.yaml" ]; then
  AGENTS_PATH=$(ls ~/.otherness/otherness-config-template.yaml 2>/dev/null \
    && echo ~/.otherness/otherness-config-template.yaml \
    || echo "")

  if [ -n "$AGENTS_PATH" ]; then
    cp "$AGENTS_PATH" otherness-config.yaml
    echo "Created otherness-config.yaml from template."
  else
    cat > otherness-config.yaml << 'EOF'
project:
  name: my-project
  repo: owner/repo
  report_issue: 1
  board_url: ""
  pr_label: ""

maqa:
  mode: standalone
  agents_path: ~/.otherness/agents
  status_update_cycles: 5
  product_validation_cycles: 3
  autonomous_mode: true

ci:
  provider: github-actions
  github_actions:
    workflow: ci.yml
  wait_timeout_seconds: 1200
  block_on_red: true

monitor:
  projects: []

github_projects:
  project_id: ""
  project_number: ""
  linked_repo: owner/repo
EOF
    echo "Created otherness-config.yaml (minimal template — no ~/.otherness found)."
  fi
fi
```

## Step 2 — Auto-fill project identity from git remote

```bash
REMOTE=$(git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||;s|\.git$||')
if [ -n "$REMOTE" ]; then
  python3 - "$REMOTE" << 'EOF'
import re, sys
repo = sys.argv[1]
name = repo.split('/')[-1]
content = open('otherness-config.yaml').read()
content = re.sub(r'(  repo:\s*)owner/repo', f'\\g<1>{repo}', content)
content = re.sub(r'(  name:\s*)my-project', f'\\g<1>{name}', content)
content = re.sub(r'(  linked_repo:\s*)owner/repo', f'\\g<1>{repo}', content)
open('otherness-config.yaml', 'w').write(content)
print(f"Set project.repo = {repo}, project.name = {name}")
EOF
fi
```

## Step 3 — Ensure ~/.otherness is cloned

```bash
if [ ! -d ~/.otherness ]; then
  REMOTE_URL=$(git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]\([^/]*\)/.*|\1|')
  git clone --quiet "git@github.com:${REMOTE_URL}/otherness.git" ~/.otherness 2>/dev/null || \
  git clone --quiet "https://github.com/${REMOTE_URL}/otherness.git" ~/.otherness 2>/dev/null || \
  echo "Could not auto-clone otherness. Clone manually: git clone git@github.com:<owner>/otherness.git ~/.otherness"
fi
```

## Step 4 — Deploy otherness command files into this project

OpenCode reads slash commands from `.opencode/command/` in the current project directory.
Copy the command files from `~/.otherness` so `/otherness.run`, `/otherness.onboard`, etc. work.

```bash
if [ -d ~/.otherness/.opencode/command ]; then
  mkdir -p .opencode/command
  # Copy all otherness.*.md commands — skip any that already exist (don't overwrite customisations)
  for src in ~/.otherness/.opencode/command/otherness.*.md; do
    fname=$(basename "$src")
    dest=".opencode/command/$fname"
    if [ ! -f "$dest" ]; then
      cp "$src" "$dest"
      echo "  Deployed: $fname"
    else
      echo "  Already present (skipped): $fname"
    fi
  done
  echo "Commands deployed to .opencode/command/"
else
  echo "WARNING: ~/.otherness/.opencode/command not found. Clone otherness first (Step 3)."
fi
```

## Step 4b — Migrate .maqa/ → .otherness/ (upgrade from older otherness versions)

```bash
if [ -d ".maqa" ] && [ ! -d ".otherness" ]; then
  mv .maqa .otherness
  echo "Migrated .maqa/ → .otherness/"
elif [ -d ".maqa" ] && [ -d ".otherness" ]; then
  echo "Both .maqa/ and .otherness/ exist — .otherness/ takes precedence. Remove .maqa/ when confirmed."
fi
```

## Step 5 — Ensure .otherness/state.json exists

```bash
mkdir -p .otherness
if [ ! -f .otherness/state.json ]; then
  REPO=$(git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||;s|\.git$||')
  python3 - "$REPO" << 'EOF'
import json, sys, datetime
repo = sys.argv[1]
state = {
  "version": "1.3",
  "mode": "standalone",
  "repo": repo,
  "current_queue": None,
  "features": {},
  "engineer_slots": {"ENGINEER-1": None, "ENGINEER-2": None, "ENGINEER-3": None},
  "bounded_sessions": {},
  "session_heartbeats": {
    "STANDALONE": {"last_seen": None, "cycle": 0}
  },
  "handoff": None
}
with open('.otherness/state.json', 'w') as f:
     json.dump(state, f, indent=2)
print("Created .otherness/state.json")
EOF
fi
```

## Step 6 — Create _state branch for state persistence

The `_state` branch is where otherness stores its persistent memory across sessions.
It must exist on the remote before `/otherness.run` can write state.

```bash
if ! git ls-remote --heads origin _state | grep -q '_state'; then
  echo "Creating _state branch for state persistence..."
  CURRENT_BRANCH=$(git branch --show-current)
  REPO=$(git remote get-url origin 2>/dev/null | sed 's|.*github.com[:/]||;s|\.git$||')

  # Create an orphan branch (no shared history with main)
  git checkout --orphan _state
  git rm -rf . --quiet 2>/dev/null || true   # clear index — orphan starts empty

  # Write initial state.json
  mkdir -p .otherness
  python3 - "$REPO" << 'EOF'
import json, sys
repo = sys.argv[1]
state = {
  "version": "1.3",
  "mode": "standalone",
  "repo": repo,
  "current_queue": None,
  "features": {},
  "engineer_slots": {"ENGINEER-1": None, "ENGINEER-2": None, "ENGINEER-3": None},
  "bounded_sessions": {},
  "session_heartbeats": {"STANDALONE": {"last_seen": None, "cycle": 0}},
  "handoff": None
}
with open('.otherness/state.json', 'w') as f:
    json.dump(state, f, indent=2)
print("Wrote .otherness/state.json")
EOF

  git add .otherness/state.json
  git commit -m "state: initialize _state branch"
  git push origin _state
  git checkout "$CURRENT_BRANCH" --quiet
  echo "_state branch created and pushed."
else
  echo "_state branch already exists — skipping."
fi
```

## Done

Edit `otherness-config.yaml` to set your `BUILD_COMMAND`, `TEST_COMMAND`, `LINT_COMMAND`, and other project-specific values. If your project has a UI, add `project.job_family: FEE`; for platform/infrastructure projects use `SysDE`; backend-only projects can omit the field (defaults to `SDE`).

Then run `/otherness.run` to start the autonomous team.
