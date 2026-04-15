# Tasks: #45 cross-project fleet health dashboard

- [ ] Read spec.md
- [ ] Read current `.opencode/command/otherness.status.md` — understand existing behavior
- [ ] Add `fleet.projects` section to `~/.otherness/otherness-config.yaml` with 4 known projects
- [ ] Add commented `fleet:` section to `otherness-config-template.yaml`
- [ ] Add Step 0 (fleet detection) to `otherness.status.md`
- [ ] Implement fleet health query (see spec.md §Expected output for format)
- [ ] Test: run `/otherness.status` from `~/.otherness` — verify table appears
- [ ] Test: verify a project with stale `_state` shows ⚠️
- [ ] Run `bash scripts/validate.sh && bash scripts/lint.sh`
- [ ] Open PR — HIGH tier — autonomous merge if CI passes

## Concrete success criterion

```bash
# From ~/.otherness, run status and verify all 4 projects appear:
# (simulate by checking output contains expected project names)
/otherness.status 2>&1 | grep -c "alibi\|kro-ui\|kardinal\|otherness" | xargs test 4 -le
echo $? # must be 0 (PASS)
```
