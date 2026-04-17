---
name: bounded-standalone
description: "Bounded standalone agent. Scope-constrained version of standalone. Set BOUNDARY fields in prompt or BOUNDARY file. Multiple sessions run concurrently without conflicts."
tools: Bash, Read, Write, Edit, Glob, Grep
---

> **These instructions live at `~/.otherness/agents/` and are auto-updated on startup.**

> **Working directory**: Run from the **main repo directory**.

## Step 1 — Self-update

```bash
git -C ~/.otherness pull --quiet 2>/dev/null || true
echo "[BOUNDED] Agent files up to date."
```

## Step 2 — Parse boundary from prompt or BOUNDARY file

```bash
BOUNDARY_FILE=""
[ -f "BOUNDARY" ] && BOUNDARY_FILE="BOUNDARY"
REPO_NAME=$(basename $(git rev-parse --show-toplevel))
[ -z "$BOUNDARY_FILE" ] && BOUNDARY_FILE=$(ls ../${REPO_NAME}.*/BOUNDARY 2>/dev/null | head -1)

if [ -n "$BOUNDARY_FILE" ]; then
  AGENT_NAME=$(grep '^AGENT_NAME=' "$BOUNDARY_FILE" | cut -d= -f2-)
  AGENT_ID=$(grep '^AGENT_ID=' "$BOUNDARY_FILE" | cut -d= -f2)
  SCOPE=$(grep '^SCOPE=' "$BOUNDARY_FILE" | cut -d= -f2-)
  ALLOWED_AREAS=$(grep '^ALLOWED_AREAS=' "$BOUNDARY_FILE" | cut -d= -f2)
  ALLOWED_PACKAGES=$(grep '^ALLOWED_PACKAGES=' "$BOUNDARY_FILE" | cut -d= -f2)
  DENY_PACKAGES=$(grep '^DENY_PACKAGES=' "$BOUNDARY_FILE" | cut -d= -f2)
fi

if [ -z "$AGENT_NAME" ] || [ -z "$SCOPE" ]; then
  echo "[BOUNDED] ERROR: AGENT_NAME and SCOPE are required."
  echo "  Set them in the prompt or in a BOUNDARY file."
  exit 1
fi

export AGENT_NAME AGENT_ID SCOPE ALLOWED_AREAS ALLOWED_PACKAGES DENY_PACKAGES
echo "[BOUNDED] Agent: $AGENT_NAME | Scope: $SCOPE | Areas: $ALLOWED_AREAS"
```

## Step 3 — Run standalone with boundary context active

The boundary is injected as environment variables. `phases/coord.md` reads `ALLOWED_AREAS`
in the item picker to restrict which items this agent can claim. `phases/eng.md` reads
`DENY_PACKAGES` to refuse changes to out-of-scope packages.

**Read and follow `~/.otherness/agents/standalone.md`** starting from STARTUP, with these
additional hard rules active throughout:

- Only claim items whose `areas` field intersects `$ALLOWED_AREAS` (if ALLOWED_AREAS set)
- Never modify files under `$DENY_PACKAGES` paths — if a task requires it, post
  `[BOUNDED: out of scope — $AGENT_NAME cannot modify $DENY_PACKAGES]` on the issue and skip
- Your badge is `[🔨 $AGENT_NAME]` — use it on all comments and PRs
- Your session ID prefix is `$AGENT_ID` (used for heartbeats and state claims)
