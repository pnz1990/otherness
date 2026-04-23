# spec: SCAN 5 time-based staleness trigger (issue-950)

## Design reference

- **Design doc**: `docs/design/42-vision-scan-to-shipped-gap.md`
- **Section**: `§ Future` item 42.4
- **Issue**: https://github.com/pnz1990/otherness/issues/950
- **Status**: in_progress

---

## Zone 1 — Obligations

**O1** SCAN 5 must add a time-based staleness trigger: if pressure block not rewritten in >30 days, add a `🔲 Future` item regardless of keyword match rate.

**O2** Age detection: look for `<!-- pressure-rewritten: YYYY-MM-DD -->` in the workflow file. If absent: treat as stale (conservative).

**O3** Time-based trigger must only fire when keyword-match threshold has NOT already fired (to avoid duplicate Future items).

**O4** The Future item added must be distinct from the keyword-match rewrite item (different marker text: "time-based staleness").

**O5** Fail-open: if age cannot be determined, treat as stale and trigger.

---

## Zone 2 — Implementer's judgment

- PRESSURE_STALE_DAYS = 30
- Conservative default (no timestamp = stale) ensures the trigger fires on first scan after this feature ships, surfacing the missing timestamp as a gap.
- `import datetime` moved inside the time-check block to avoid import errors in edge cases.

---

## Acceptance criteria

- [ ] `agents/vibe-vision-auto.md` contains Step 4 (§42.4) time-based staleness trigger
- [ ] Trigger uses `<!-- pressure-rewritten: YYYY-MM-DD -->` detection
- [ ] Trigger suppressed when keyword-match already fired
- [ ] Design doc 42 §42.4 moved to ✅ Present
- [ ] `bash scripts/validate.sh` passes
- [ ] `bash scripts/lint.sh` passes
