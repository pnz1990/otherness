# spec: design doc 35 housekeeping — mark shipped items ✅ (issue-856)

## Design reference

- **Design doc**: `docs/design/35-vision-alignment-signal.md`
- **Section**: `§ Future`
- **Issue**: https://github.com/pnz1990/otherness/issues/856
- **Status**: in_progress

---

## Zone 1 — Obligations

**O1** Remove stale `🔲` entries for items already shipped (35.2, 35.3, 35.5 were all implemented in SM phases but not cleaned from Future section).

**O2** Add `✅ 35.5` to Present section confirming `vision_aligned` and `consecutive_vision_misaligned` are persisted to `_state` branch.

**O3** Future section must not contain items already present in ✅ Present.

---

## Acceptance criteria

- [ ] `docs/design/35-vision-alignment-signal.md` Future section has no stale 🔲 entries for shipped items
- [ ] `✅ 35.5` added to Present section
- [ ] `bash scripts/validate.sh` passes
