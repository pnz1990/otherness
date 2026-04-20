# Spec: Skill Decay Tracking

## Design reference
- **Design doc**: `docs/design/31-stage-2-skills-expansion.md`
- **Section**: `§ Future` (implicitly — from issue body referencing design doc 35)
- **Implements**: `SM §4c`: skill decay tracking — skills added >90 days ago without a PROVENANCE.md "reinforced" entry are candidates for revision (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — SM §4c runs skill decay check every 10 SM cycles (same cadence as skill confidence check).**

**O2 — A skill is "stale" if:** its file was last modified >90 days ago AND `PROVENANCE.md` does not contain "reinforced: <skill-name>" or "## <YYYY-MM-DD>" with the skill name in the subsequent 14 days.

**O3 — For each stale skill:** post a comment on the report issue listing the stale skills with their age.
Do NOT open issues (too noisy). Informational log only.

**O4 — Graceful fallback:** if skills directory missing or PROVENANCE.md missing: skip without error.

---

## Zone 2 — Implementer's judgment

- What counts as "use signal": skill name appears in PROVENANCE.md within last 90 days.
  File modification date is the proxy for "added date" (conservative).

---

## Zone 3 — Scoped out

- Auto-deleting stale skills (requires human judgment)
- Tracking usage in PR bodies or session comments (complex scraping)
