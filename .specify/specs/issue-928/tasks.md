# Tasks: issue-928

- [AI] Read current SCAN 5 `_extract_bullets` logic in `agents/vibe-vision-auto.md`
- [CMD] Locate the exact line range of SCAN 5 in `agents/vibe-vision-auto.md`
- [AI] Write enhanced `_extract_bullets` that extracts domain nouns from bullet text
- [AI] Write matching logic that tests domain noun dict against evidence items
- [CMD] cd $MY_WORKTREE && grep -n "def _extract_bullets" agents/vibe-vision-auto.md → confirm location
- [AI] Edit `agents/vibe-vision-auto.md` to expand noun extraction
- [AI] Update `docs/design/17-vision-evolution-cadence.md`: flip 🔲 → ✅ for this item
- [CMD] Verify: grep -q "DOMAIN_NOUNS\|domain_nouns\|onboard" agents/vibe-vision-auto.md → expected: match
- [AI] Write commit + open PR
