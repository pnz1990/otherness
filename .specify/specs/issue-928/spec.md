# Spec: issue-928 — SCAN 5 noun extraction expansion (design doc 17 Future → ✅)

## Design reference
- **Design doc**: `docs/design/17-vision-evolution-cadence.md`
- **Section**: `§ Future`
- **Implements**: Vision evolution cadence must have a defined "pressure addressed" criterion that makes the lens bullet for onboarding and visibility SCAN-5-scorable

---

## Zone 1 — Obligations

**O1 — SCAN 5 topic matching must use domain-noun extraction, not raw first-30-char prefix.**
The `_extract_bullets` function produces `(text, topic)` pairs where `topic = text[:30].lower()`.
For bullets like "Is the onboarding good enough?", topic = "is the onboarding good enough".
This substring never appears in PR titles. Instead, SCAN 5 must extract key domain nouns
from the bullet text and match any of them against evidence.

**O2 — The domain noun set must include onboarding and visibility synonyms.**
Extended domain noun dictionary must include at minimum:
`{'onboard', 'setup', 'dashboard', 'health', 'visib', 'progress', 'status', 'report',
'schema', 'first-run', 'setup-guide', 'metrics', 'quality', 'learn', 'skill', 'session'}`

**O3 — A bullet is "addressed" when ≥2 evidence items match ANY domain noun from the expanded set.**
Evidence matching continues to be: PR titles + Present doc items.
Matching: check if any word from the domain-noun dictionary appears in the evidence item.

**O4 — Backward compatibility: if no domain noun is found in a bullet, fall back to topic[:30] matching.**
Bullets that have no extractable domain noun still use the current first-30-char approach.

**O5 — Verification: after implementing, run SCAN 5 against current evidence.**
Check that onboarding and visibility bullets score > 0 matches.
Verified by: `grep -q "SCAN 5.*Bullet.*onboard\|SCAN 5.*Bullet.*visib" <output>`

---

## Zone 2 — Implementer's judgment

- The domain noun dictionary is additive — it can grow over time.
- Order of noun matching: try each domain noun against evidence; count unique evidence items that match ANY noun.
- The fix is in `agents/vibe-vision-auto.md` SCAN 5 bullet extraction + scoring logic.

---

## Zone 3 — Scoped out

- Full NLP/tokenization of bullet text
- Noun extraction for non-English bullets
- Changing the STALENESS_THRESHOLD
- Changes to SCAN 1-4
