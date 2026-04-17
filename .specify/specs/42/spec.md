# Spec: fix remaining git push origin main violations

**Issue:** #42
**Size:** XS
**Risk tier:** CRITICAL (standalone.md line 763) + CRITICAL (bounded-standalone.md line 425)
**Depends on:** PR #36 merged (fixes standalone.md lines 170 and 425)

## Obligations (Zone 1)

1. `agents/standalone.md` must contain zero instances of `git push origin main` outside of comments or quoted strings that explain what NOT to do.

2. `agents/bounded-standalone.md` must contain zero instances of `git push origin main`.

3. Every state write must use the canonical `STATE_MSG` + write block pattern.

4. The QA cleanup block (Phase 3, after `gh pr merge`) must update state via the canonical write block, not via a direct main push.

5. The bounded claim section must update state via the canonical write block.

## Implementer's judgment (Zone 2)

The exact STATE_MSG string content.

## Scoped out (Zone 3)

Lines 170 and 425 of standalone.md — already fixed by PR #36, do not re-touch them.

## Exact changes

### standalone.md line 763 — Phase 3 QA cleanup

Replace:
```bash
git add .otherness/state.json
git commit -m "state: [$MY_SESSION_ID] $ITEM_ID done"
git push origin main
```

With:
```bash
export STATE_MSG="[$MY_SESSION_ID] $ITEM_ID done"
# run the STATE MANAGEMENT write block from the top of this file
```

### bounded-standalone.md line 425 — claim section

Replace:
```bash
git add .otherness/state.json
git commit -m "state: [$AGENT_NAME] claimed #$NEXT_ISSUE"
git push origin main
```

With:
```bash
export STATE_MSG="[$AGENT_NAME] claimed #$NEXT_ISSUE"
# run the STATE MANAGEMENT write block from the top of this file
```

## Verification

```bash
grep -n "push origin main" agents/standalone.md agents/bounded-standalone.md
# Only allowed output: lines containing the string in a comment explaining what NOT to do
# Zero matches = PASS
```

---

## Design reference
- N/A — pre-DDDD item (written before design doc system, PR #144)
