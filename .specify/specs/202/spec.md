# Spec: fix lint.sh to cover agents/phases/*.md (#202)

## Design reference
- N/A — tooling fix with no user-visible behavior change

## Zone 1 — Obligations

**O1** — `scripts/lint.sh` checks CRLF and null bytes for all files in `agents/phases/*.md`.

Falsifiable: `bash scripts/lint.sh` would catch a CRLF-contaminated phase file.

**O2** — The existing check loop is extended in-place; no other lint behavior changes.

Falsifiable: `bash scripts/lint.sh` still passes with no spurious errors on the current clean files.

## Zone 2 — Implementer's judgment
- One glob added to the for loop: `"$AGENTS_DIR/phases"/*.md`

## Zone 3 — Scoped out
- Adding structural checks for phase file content (headers, etc.) — only CRLF/null coverage
