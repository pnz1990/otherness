# Tasks: #45 cross-project fleet health dashboard

- [ ] Read spec.md
- [ ] Read current `.opencode/command/otherness.status.md` — understand existing behavior
- [ ] Add `monitor.projects` section to `~/.otherness/otherness-config.yaml` with your managed projects
- [ ] Add commented `monitor:` section to `otherness-config-template.yaml` (already done in generics PR)
- [ ] Add Step 0 (fleet detection) to `otherness.status.md`
- [ ] Implement fleet health query (see spec.md §Expected output for format)
- [ ] Test: run `/otherness.status` — verify table appears with configured projects
- [ ] Test: verify a project with stale `_state` shows ⚠️
- [ ] Run `bash scripts/validate.sh && bash scripts/lint.sh`
- [ ] Open PR — HIGH tier — autonomous merge if CI passes

## Concrete success criterion

```bash
# Verify fleet output contains at least one configured project name:
# Replace <project-name> with the first entry in monitor.projects
/otherness.status 2>&1 | grep -q "<project-name>" && echo "PASS" || echo "FAIL"
```
