# Spec: vibe-vision.md hard rule — session termination

> Item: 267 | Created: 2026-04-18 | Status: Active

## Design reference
- **Design doc**: `docs/design/07-d4-enforcement.md`
- **Section**: `## Future`
- **Implements**: `vibe-vision.md` hard rule: session ends after artifacts are on main (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — HARD RULES section in vibe-vision.md includes an explicit session termination rule.**
The `## HARD RULES` section must include a rule that explicitly states:
"Session ends when artifacts land on main. Do not implement, do not open issues,
do not create branches, do not merge PRs after the vibe-vision session."

Behavior that violates this: the HARD RULES section has no mention of session
termination after artifacts are on main. The rule must be unambiguous.

**O2 — The rule is in the HARD RULES section, not the MODE block.**
The MODE block already has a shorter version. The HARD RULES section is where
human-readable enforcement statements live. The full termination rule belongs there.

Behavior that violates this: a new HARD RULE is added to the MODE block instead of HARD RULES.

**O3 — Design doc 07 marks this item as ✅ Present.**

Behavior that violates this: doc 07 still shows `vibe-vision.md` hard rule as 🔲.

---

## Zone 2 — Implementer's judgment

- Whether to modify the MODE block: no. Add to HARD RULES only.
- Whether to add a new STEP for session termination: no. HARD RULES is sufficient.
- Exact wording: "**Session ends after landing.** Once D4 artifacts are on main,
  the session is complete. Do not proceed to implementation. Do not open GitHub
  issues. Do not create feat/* branches. Do not write specs or code. The autonomous
  execution team picks up from here."

---

## Zone 3 — Scoped out

- Changes to how the session ends mechanically (no new commands)
- Adding a termination signal to the conversation (the rule is instructional only)
