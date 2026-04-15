# Spec: state.json schema migration

**Issue:** #44
**Size:** S
**Risk tier:** CRITICAL (standalone.md) + LOW (scripts/test.sh)

## Obligations (Zone 1)

1. Immediately after reading `state.json` at startup, `standalone.md` must run a migration check. If `state.version != "1.3"`, it upgrades the schema in-place and writes the updated file back to disk.

2. The migration is **idempotent**: running it on a v1.3 state.json makes no changes and writes nothing.

3. The migration handles **v1.2 → v1.3** specifically:
   - Rename `project` key to `repo` (if `project` exists and `repo` does not)
   - Add `engineer_slots: {ENGINEER-1: null, ENGINEER-2: null, ENGINEER-3: null}` if missing
   - Add `bounded_sessions: {}` if missing
   - Add `handoff: null` if missing
   - Set `version: "1.3"`

4. If `state.json` is missing or unparseable, the migration creates a minimal valid v1.3 state.json with the `repo` field populated from `git remote get-url origin`.

5. `scripts/test.sh` adds a check that warns (non-fatal) when the reference project is not on schema v1.3.

## Implementer's judgment (Zone 2)

- Exact log message format.
- Whether to print a diff of what changed (useful for debugging) or just a summary.

## Scoped out (Zone 3)

- This spec does not define v1.4 or future schema versions.
- This spec does not push the migrated state to `_state` branch — the next state write will naturally persist it.

## Implementation

### Migration block — insert after state read in standalone.md

```python
python3 - << 'EOF'
import json, os, subprocess

# Read state
try:
    with open('.otherness/state.json') as f:
        s = json.load(f)
except Exception:
    # Missing or corrupt — create fresh
    repo_raw = subprocess.check_output(['git','remote','get-url','origin'],text=True).strip()
    repo = repo_raw.split('github.com')[-1].strip(':/').rstrip('.git').rstrip('/')
    s = {}
    # Force migration by setting a fake old version
    s['version'] = '0.0'

v = s.get('version','0.0')
if v == '1.3':
    exit(0)  # already current

changed = []

# v1.2 → v1.3: rename 'project' → 'repo'
if 'project' in s and 'repo' not in s:
    s['repo'] = s.pop('project')
    changed.append("renamed 'project' → 'repo'")

# Add missing fields
defaults = {
    'version': '1.3',
    'mode': 'standalone',
    'current_queue': None,
    'features': {},
    'engineer_slots': {'ENGINEER-1': None, 'ENGINEER-2': None, 'ENGINEER-3': None},
    'bounded_sessions': {},
    'session_heartbeats': {'STANDALONE': {'last_seen': None, 'cycle': 0}},
    'handoff': None
}

# Ensure repo is set
if not s.get('repo'):
    try:
        repo_raw = subprocess.check_output(['git','remote','get-url','origin'],text=True).strip()
        s['repo'] = repo_raw.split('github.com')[-1].strip(':/').rstrip('.git').rstrip('/')
        changed.append(f"set repo={s['repo']}")
    except Exception:
        pass

for k, default in defaults.items():
    if k not in s:
        s[k] = default
        changed.append(f"added {k}")
s['version'] = '1.3'

os.makedirs('.otherness', exist_ok=True)
with open('.otherness/state.json', 'w') as f:
    json.dump(s, f, indent=2)
print(f"[STANDALONE] Migrated state.json to v1.3: {', '.join(changed)}")
EOF
```

### scripts/test.sh — schema check (non-fatal)

```bash
# After reference project alive check, add:
echo "[5b] Checking reference project state schema version..."
REF_VER=$(gh api "repos/$REFERENCE_PROJECT/contents/.otherness%2Fstate.json?ref=_state" \
  --jq '.content' 2>/dev/null | base64 -d 2>/dev/null | \
  python3 -c "import json,sys; print(json.load(sys.stdin).get('version','?'))" 2>/dev/null || echo "?")
if [ "$REF_VER" = "1.3" ]; then
  echo "  OK: state.json is v1.3"
else
  echo "  WARN: state.json is v$REF_VER (expected 1.3) — migration runs at next startup"
fi
```

## Verification

```bash
# Create a v1.2 state.json and run migration:
echo '{"version":"1.2","project":"pnz1990/test","features":{}}' > .otherness/state.json
python3 - << 'EOF'
# paste migration block here
EOF
python3 -c "import json; s=json.load(open('.otherness/state.json')); print(s.get('version'), s.get('repo'), 'engineer_slots' in s)"
# Must print: 1.3 pnz1990/test True
```
