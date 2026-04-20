# Spec: Scenarios 13-15 — policy gate completeness

## Design reference
- **Design doc**: `docs/design/25-anchor-kardinal-promoter.md`
- **Section**: `§ Future`
- **Implements**: Scenarios 13-15: policy gate completeness (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — Scenarios 13, 14, 15 added to kardinal-promoter PDCA workflow.**
Each scenario must have a dedicated section with pass/fail tracking and RESULTS entry.
- S13: policy simulate on prod/weekend returns BLOCKED (multiple gates enforced)
- S14: policy simulate with custom expression returns deterministic output
- S15: `kardinal override` command executes and creates audit record
Violation: any of S13/S14/S15 missing from PDCA after merge.

**O2 — Design doc 25 marks item as ✅ Present.**
The 🔲 Future item must be moved to ✅ Present.

---

## Zone 2 — Implementer's judgment

- S13 reuses the weekend simulation time (same as S3) — different assertion
- S14: "deterministic output" is the test (not specific BLOCKED/PASS since soak time varies)
- S15: `kardinal override` may fail if pipeline not in right state — non-fatal (⚠️ not ❌)
- Implementation in kardinal-promoter PR #874

---

## Zone 3 — Scoped out

- Testing the actual gate override effectiveness (would need specific cluster state)
- S16-18 (health adapter coverage) — separate issue
