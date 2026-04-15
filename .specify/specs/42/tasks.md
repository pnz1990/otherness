# Tasks: #42 fix remaining push-to-main violations

- [ ] Confirm PR #36 is merged (prerequisite)
- [ ] Run `grep -n "push origin main" agents/standalone.md` — expect lines 170, 425 gone, line 763 still present
- [ ] Fix standalone.md line 763 (QA cleanup, see spec.md)
- [ ] Run `grep -n "push origin main" agents/bounded-standalone.md` — expect line 425
- [ ] Fix bounded-standalone.md line 425 (claim section, see spec.md)
- [ ] Run `grep -c "push origin main" agents/standalone.md agents/bounded-standalone.md`
  — must be 0 (except comment lines)
- [ ] Run `bash scripts/validate.sh && bash scripts/lint.sh`
- [ ] Open PR — CRITICAL tier — post [NEEDS HUMAN]

## Concrete success criterion

```bash
grep -v "^.*#\|Never\|Always use\|exception" agents/standalone.md agents/bounded-standalone.md \
  | grep "push origin main" | wc -l
```
Must output `0`.
