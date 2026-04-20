# Spec: SM §4c Learn-Cadence Enforcement

## Design reference
- **Design doc**: `docs/design/31-stage-2-skills-expansion.md`
- **Section**: `§ Future`
- **Implements**: `SM §4c` learn-cadence enforcement: explicit 14-day PROVENANCE.md check every batch (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — SM §4c runs a PROVENANCE.md date check every batch.**
Reads last `## YYYY-MM-DD` entry from `~/.otherness/agents/skills/PROVENANCE.md`.
Computes `days_since`. If PROVENANCE.md missing or no entries: `days_since = 999`.

**O2 — If days_since < 14: no action (cadence OK).**
Log `[SM §4c] Learn cadence OK — Nd < 14d floor.`

**O3 — If days_since >= 14 AND no open learn issue AND no active learn branch: open priority/high issue.**
Issue title: `learn(arch): cadence enforcement — PROVENANCE.md overdue (Nd since last learn)`
Labels: `otherness,priority/high,area/skills,kind/chore`

**O4 — If days_since >= 14 AND open learn issue OR active learn branch: skip (already in flight).**
Log that issue or branch is active — cadence satisfied in-flight.

**O5 — Graceful fallback: if gh CLI fails, skip without error.**

---

## Zone 2 — Implementer's judgment

- Check runs every batch (not every 10 cycles) — the 14-day floor is important enough to check always.

---

## Zone 3 — Scoped out

- Actually running `/otherness.learn` inline (separate §4d-learn)
- Checking paradigm diversity of learn sessions (separate issue 619)
