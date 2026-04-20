# spec: issue-572 — add journeys_dir to anchor: section in template

## Design reference
- N/A — infrastructure change with no user-visible behavior

## Zone 1 — Obligations

O1: `otherness-config-template.yaml` `anchor:` section MUST include a commented-out `journeys_dir` field.
- Violation: anchor: section exists but does not contain `journeys_dir`.

O2: The comment text MUST explain what `journeys_dir` is used for (SM §4g-anchor-parity).
- Violation: field is present but has no explanatory comment.

O3: The field MUST be commented out (prefixed with `#`) so it does not affect projects that don't use it.
- Violation: field is uncommented and would be active by default.

## Zone 2 — Implementer's judgment

- Exact wording and indentation is up to the implementer, following the pattern of existing commented-out fields.
- Placement: after the existing `# upstream_version_file` and `# upstream_version_pattern` lines.

## Zone 3 — Scoped out

- Changing any other template fields
- Updating otherness-config.yaml for any project
- Documenting journeys_dir beyond the inline comment
