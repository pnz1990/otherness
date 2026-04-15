# Tasks: #47 validate.sh structural detection

- [ ] Read spec.md
- [ ] Read current validate.sh check [1/4] (lines ~15–30)
- [ ] Replace FORBIDDEN_PATTERNS block with structural detection (see spec.md)
- [ ] Test 1: add pnz1990/kro-ui to an agent file → validate.sh must fail
- [ ] Test 2: verify pnz1990/otherness reference is allowed → validate.sh passes
- [ ] Test 3: run full `bash scripts/validate.sh` → must pass
- [ ] Run `bash scripts/lint.sh`
- [ ] Open PR — LOW tier — autonomous merge if CI passes

## Concrete success criterion

```bash
echo "test pnz1990/kro-ui path" >> agents/skills/test-probe.md
bash scripts/validate.sh 2>&1 | grep -q "ERROR.*kro-ui" && echo "PASS" || echo "FAIL"
rm agents/skills/test-probe.md
bash scripts/validate.sh && echo "STILL PASSES" || echo "BROKEN"
```
Both lines must print PASS / STILL PASSES.
