#!/usr/bin/env bash
# scripts/run-forever.sh
#
# Runs otherness perpetually by re-invoking /otherness.run after each session ends.
# OpenCode sessions naturally end after context window exhaustion (~50 minutes of
# continuous work). This wrapper ensures the loop is truly perpetual without human
# intervention.
#
# Usage (from the project directory):
#   bash ~/.otherness/scripts/run-forever.sh
#
# Or with a custom project path:
#   bash ~/.otherness/scripts/run-forever.sh /path/to/project
#
# Stop gracefully:
#   touch .otherness/stop-after-current
#   (the agent finishes its current item then exits cleanly on the next cycle)
#
# Stop immediately:
#   Ctrl+C (kills the wrapper; any in-progress worktree is cleaned up on next run
#   via the stale worktree detection added in PR #16)

set -euo pipefail

PROJECT_DIR="${1:-$(pwd)}"
cd "$PROJECT_DIR"

# Verify this is an otherness project
if [ ! -f "otherness-config.yaml" ]; then
  echo "Error: otherness-config.yaml not found in $PROJECT_DIR"
  echo "Run from the root of an otherness-managed project."
  exit 1
fi

REPO=$(python3 -c "
import re
for line in open('otherness-config.yaml'):
    m = re.match(r'^\s+repo:\s*(\S+)', line)
    if m: print(m.group(1)); break
" 2>/dev/null || echo "unknown")

echo "otherness-run-forever: starting perpetual loop for $REPO"
echo "Stop gracefully: touch .otherness/stop-after-current"
echo "Stop immediately: Ctrl+C"
echo ""

CYCLE=0
while true; do
  CYCLE=$((CYCLE + 1))
  TIMESTAMP=$(date -u '+%Y-%m-%d %H:%M UTC')

  # Check for graceful stop sentinel
  if [ -f ".otherness/stop-after-current" ]; then
    echo "[$TIMESTAMP] Stop sentinel found — exiting."
    break
  fi

  echo "[$TIMESTAMP] Starting session $CYCLE..."
  echo "────────────────────────────────────────"

  # Run one otherness session via OpenCode
  # opencode run executes the slash command and exits when the session ends
  if command -v opencode &>/dev/null; then
    opencode run "/otherness.run" 2>&1 || true
  else
    echo "Error: opencode CLI not found. Install from https://opencode.ai"
    exit 1
  fi

  echo "────────────────────────────────────────"
  echo "[$TIMESTAMP] Session $CYCLE ended. Restarting in 10s..."
  echo "(Ctrl+C to stop, or touch .otherness/stop-after-current for graceful stop)"
  sleep 10
done

echo "otherness-run-forever: stopped."
