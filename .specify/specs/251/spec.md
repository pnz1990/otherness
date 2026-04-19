# Spec: Issue body must identify design doc Future item

> Item: 251 | Created: 2026-04-18 | Status: Active

## Design reference
- **Design doc**: `docs/design/01-declarative-design-driven-development.md`
- **Section**: `## Future`
- **Implements**: Issue body must identify design doc Future item (🔲 → ✅)

---

## Zone 1 — Obligations

**O1 — COORD queue-gen issue bodies include `## Design reference` when sourced from a design doc.**
The `[AI-STEP]` comment in coord.md §1c must be updated to explicitly require the issue
body to include a `## Design reference` section in this exact format:

```
## Design reference
- **Design doc**: `docs/design/<filename>`
- **Section**: `§ Future`
- **Implements**: <item description> (🔲 → ✅)
```

Behavior that violates this: an issue created by COORD queue-gen from a design doc item
has no `## Design reference` section in its body.

**O2 — Issues sourced from roadmap (no design doc) include a note to create a design doc.**
When an item comes from `roadmap.md` (the fallback path, no design doc), the issue body
must include a note in the body: "Note: no `docs/design/` file covers this area. Creating
one should be part of this item's work (see eng.md §2b O1)."

Behavior that violates this: roadmap-sourced issues are created without any note about
missing design docs.

**O3 — The `[AI-STEP]` comment in coord.md §1c is updated to be explicit about the format.**
The existing stub says "issue body must reference that design doc". This must be strengthened
to specify the exact `## Design reference` format, so the AI step has a precise template to
follow when creating issues.

Behavior that violates this: the stub remains as loose prose without the exact template.

---

## Zone 2 — Implementer's judgment

- Whether to add a validate.sh check for issue bodies: no — GitHub issue content is not
  checked by validate.sh (it would require API calls). The enforcement is in the
  [AI-STEP] instruction, not in automated tooling.
- Whether to retroactively add ## Design reference to existing open issues: no — this
  is forward-only. New issues created by queue-gen from this point forward will include
  it. Existing issues are not touched.
- Whether to change the `[AI-STEP]` stub for coord.md §1c into deterministic code:
  no — issue creation with a properly formatted body is an AI-level task. Keep it as
  [AI-STEP] with a more explicit template.

---

## Zone 3 — Scoped out

- Retroactively updating existing open issues (forward-only change)
- Validating that human-created issues include Design reference (humans are not required
  to follow this format — only COORD queue-gen is)
- Adding validate.sh checks for GitHub issue content
