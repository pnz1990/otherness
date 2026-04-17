# Spec: Complete Version Pinning (#115)

## Zone 1 — Obligations (falsifiable)

### O1: First release tag exists
A git tag `v0.1.0` and corresponding GitHub release exists on `pnz1990/otherness`.
- **Violation**: `gh release list --repo pnz1990/otherness --limit 1` returns empty.

### O2: /otherness.upgrade rewrites for version pinning
`.opencode/command/otherness.upgrade.md` is rewritten to:
- Show the current pinned version (from `otherness-config.yaml` `agent_version`) or "unpinned (latest)"
- List available tags with their commit subjects (changelog preview)
- Guide the user to set `agent_version: vX.Y.Z` in `otherness-config.yaml`
- **Violation**: The file contains only the old speckit/extension content with no mention of `agent_version` or `changelog`.

### O3: Acceptance test passes
```bash
grep -c "changelog\|agent_version\|bump" ~/.otherness/.opencode/command/otherness.upgrade.md
# Must return ≥ 1
```

### O4: Rollback documented in RECOVERY.md
RECOVERY.md contains a section explaining how to pin to a previous tag when a bad agent version is deployed.
- **Violation**: RECOVERY.md has no mention of version pinning or `agent_version` rollback.

---

## Zone 2 — Implementer's judgment

- Tag message for v0.1.0 (should describe the state at this point in the project).
- Whether to also update `otherness-config-template.yaml` to show a commented example.
- Exact prose in the upgrade command.

---

## Zone 3 — Scoped out

- Automated tag creation CI (manual tagging by maintainer is sufficient for now).
- Auto-bumping version on every merge (too noisy; operator-driven).
- Semantic versioning enforcement tooling.
- Projects pinned to non-existent tags — they already fall back gracefully per standalone.md.
