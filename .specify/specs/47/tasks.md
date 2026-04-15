# Tasks: #47 validate.sh structural detection

- [ ] Read spec.md
- [ ] Read current validate.sh check [1/4]
- [ ] Replace FORBIDDEN_PATTERNS block with structural detection (see spec.md)
- [ ] Test 1: add `<owner>/<fleet-project>` to an agent file → validate.sh must fail
- [ ] Test 2: verify `<owner>/otherness` reference is allowed → validate.sh passes
- [ ] Test 3: run full `bash scripts/validate.sh` → must pass
- [ ] Run `bash scripts/lint.sh`
- [ ] Open PR — LOW tier — autonomous merge if CI passes

## Concrete success criterion

```bash
# Replace <owner>/<project> with a real fleet project from your otherness-config.yaml
echo "test <owner>/<project> path" >> agents/skills/test-probe.md
bash scripts/validate.sh 2>&1 | grep -q "ERROR" && echo "PASS" || echo "FAIL"
rm agents/skills/test-probe.md
bash scripts/validate.sh && echo "STILL PASSES" || echo "BROKEN"
```
Both lines must print PASS / STILL PASSES.
