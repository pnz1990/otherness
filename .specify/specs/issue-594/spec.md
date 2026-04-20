# Spec: Mark M5b as explicitly DEFERRED in design doc

## Design reference
- **Design doc**: `docs/design/27-security-model.md`
- **Section**: `§ Future`
- **Implements**: M5b: Add 🚫 marker to DEFERRED items so queue-gen skips them (🔲 → annotated)

## Zone 1 — Obligations

**O1**: The M5b line in `docs/design/27-security-model.md` must contain `🚫` so queue-gen
regex `🔲 (?!.*🚫)` skips it on future runs.

**O2**: No new GitHub issues are created for M5b on next queue-gen run.

## Zone 2 — Implementer's judgment

Which exact annotation format to use: the design doc already says "DEFERRED" in the
body. Adding `🚫` to the start after `🔲` satisfies queue-gen's skip regex.

## Zone 3 — Scoped out

- No implementation of Bedrock ARN restriction itself (explicitly DEFERRED)
- No changes to queue-gen logic
