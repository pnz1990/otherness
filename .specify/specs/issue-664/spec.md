# Spec: issue-664 — fix JOURNEY counts show 0 when no ✅/❌ markers

## Design reference
- N/A — infrastructure bug fix (JOURNEY count display, no user-visible behavior in normal loop).

## Zone 1 — Obligations

**O1**: When `definition-of-done.md` exists but no `##` section headers contain `✅` or `❌`, JOURNEY_OK and JOURNEY_FAIL must display `?` not `0`.

**O2**: When `definition-of-done.md` is absent or unreadable, existing `?` fallback is preserved.

**O3**: When the file has at least one section with `✅` or `❌`, display the actual count (existing behavior).

## Zone 2 — Implementer's judgment

- Check: sections exist (file present, has `##` headers) AND ok+fail both 0 → `?`.
- Computing ok and fail in same block to avoid re-reading file twice per call.

## Zone 3 — Scoped out

- Changing JOURNEY display format beyond `?` placeholder
