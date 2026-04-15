# Tasks: #44 state.json schema migration

- [ ] Read spec.md
- [ ] Find the state read block in standalone.md (lines 33–34)
- [ ] Insert migration block immediately after (see spec.md §Migration block)
- [ ] Verify idempotency: run migration twice on v1.3 state — no output second time
- [ ] Verify v1.2 migration: create v1.2 state, run migration, verify v1.3 fields present
- [ ] Find schema version check location in scripts/test.sh (after line [5/5])
- [ ] Add schema version warning check (see spec.md §scripts/test.sh)
- [ ] Run `bash scripts/validate.sh && bash scripts/test.sh`
- [ ] Open PR — CRITICAL tier (standalone.md change) — post [NEEDS HUMAN]

## Concrete success criterion

```bash
echo '{"version":"1.2","project":"pnz1990/test","features":{}}' > .otherness/state.json
# run migration block
python3 -c "
import json
s=json.load(open('.otherness/state.json'))
assert s['version']=='1.3'
assert s['repo']=='pnz1990/test'
assert 'engineer_slots' in s
assert 'handoff' in s
print('PASS')
"
```
