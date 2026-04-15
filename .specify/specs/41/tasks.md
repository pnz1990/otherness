# Tasks: #41 _state branch bootstrap

## Steps

- [ ] Read spec.md (this file's companion)
- [ ] Locate Step 5 in `.opencode/command/otherness.setup.md` (ends after state.json creation)
- [ ] Add Step 6: create/push `_state` orphan branch (see spec.md §otherness.setup.md)
- [ ] Read the state write block in `agents/standalone.md` (lines 40–87)
- [ ] Add bootstrap block before `for attempt in range(3):` (see spec.md §standalone.md)
- [ ] Run `bash scripts/validate.sh` — must pass
- [ ] Run `bash scripts/lint.sh` — must pass
- [ ] Commit both files together
- [ ] Open PR — CRITICAL tier (standalone.md) — post [NEEDS HUMAN]

## Concrete success criterion

After this PR merges and a user runs `/otherness.setup` on a fresh repo:
```bash
git ls-remote --heads origin _state | grep -q _state && echo "PASS" || echo "FAIL"
```
Must print `PASS`.
