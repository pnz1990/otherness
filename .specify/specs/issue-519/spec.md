# Spec: Scenarios 16-18 — health adapter coverage

## Design reference
- **Design doc**: `docs/design/25-anchor-kardinal-promoter.md`
- **Section**: `§ Future`
- **Implements**: Scenarios 16-18: health adapter coverage (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — Scenarios 16, 17, 18 added to kardinal-promoter PDCA.**
- S16: pipeline stages spec is readable via kubectl API (HTTP health structural check)
- S17: MetricCheck CRD presence verified (Prometheus adapter infrastructure check)
- S18: pipeline spec validates via kubectl dry-run (custom health config structural check)
All three must have dedicated PDCA sections with RESULTS entries.
Violation: any scenario missing after kardinal-promoter PR #874 is merged.

**O2 — Design doc 25 marks item as ✅ Present.**
The 🔲 Future item must be moved to ✅ Present with (PR #874, date).

---

## Zone 2 — Implementer's judgment

- Real HTTP/Prometheus tests require live endpoints not available in CI. Structural checks cover the API surface.
- S17 uses ⚠️ rather than ❌ when MetricCheck CRD absent (older cluster).
- Implementation in kardinal-promoter PR #874 (same branch as S1, S13-15).

---

## Zone 3 — Scoped out

- Real Prometheus query execution (requires live Prometheus server)
- HTTP endpoint polling (requires a running service beyond the test app)
