# Tasks: #43 queue generation protocol

- [ ] Read spec.md (this file's companion)
- [ ] Read current 1b in standalone.md (line 466–467) — understand what's being replaced
- [ ] Read docs/aide/roadmap.md — understand structure (stages → deliverables)
- [ ] Read docs/aide/definition-of-done.md — understand journey format
- [ ] Write replacement 1b instruction (see spec.md §The phase 1b instruction)
- [ ] Verify: new 1b includes all 7 obligations from spec.md
- [ ] Run `bash scripts/validate.sh && bash scripts/lint.sh`
- [ ] Open PR — CRITICAL tier — post [NEEDS HUMAN]

## Concrete success criterion

After this PR merges, run `/otherness.run` on a project with empty queue. Verify:
```bash
# Each generated item must have an issue with an Acceptance section:
gh issue view <generated_item_number> --repo $REPO --json body \
  --jq '.body' | grep -q "## Acceptance" && echo "PASS" || echo "FAIL"
```
