# Spec: D4 Classification at Issue Intake — coord.md §1e executable

## Design reference
- **Design doc**: `docs/design/07-d4-enforcement.md`
- **Section**: `§ Future`
- **Implements**: D4 classification at issue intake — coord.md §1e [AI-STEP] → executable Python/bash (🔲 → ✅)

---

## Zone 1 — Obligations

**O1**: After claiming an item, coord.md §1e MUST read the issue title and body.

**O2**: The title classification MUST follow these rules:
- DECLARATIVE: title matches conventional-commit format `^(feat|fix|chore|docs|refactor|test|perf|ci|build)\(` OR title directly references a design doc 🔲 item
- INFRA: title matches maintenance patterns (bump, fix ci, fix lint, update dep, clean)
- IMPERATIVE: anything else (imperative verbs: add, make, update, remove, create, etc.)
- Title classification OVERRIDES body content

**O3**: If IMPERATIVE: MUST post a `[📋 D4 TRANSLATION]` comment on the issue. The comment format is:
```
[📋 D4 TRANSLATION]
Heard: "<issue title verbatim>"
Intent: <one sentence>
D4 layer: <vision | roadmap | design doc | spec>
Artifact: <exact text>
Proceeding immediately.
```
No 60-second sleep — the original spec said sleep but standalone.md §D4 says "Proceed immediately — no 60s wait."

**O4**: The classification logic MUST be fail-safe: if the gh API call fails, skip classification and proceed (no-op on error).

**O5**: validate.sh MUST pass after the change.

---

## Zone 2 — Implementer's judgment

- Steps 4 (scan last 5 comments for human instructions) and 5 (DECLARATIVE/INFRA no-op): implement Step 2+3 only. Steps 4+5 are lower value and can be left as no-op for now.
- Classification regex: conservative — pattern-match on common conventional-commit prefixes; unrecognized = IMPERATIVE (safe default).

---

## Zone 3 — Scoped out

- Waiting 60 seconds for human correction (blocked by standalone.md throughput requirement)
- Step 4: scanning comments for human instructions
- Creating a new GitHub issue for each comment translation
