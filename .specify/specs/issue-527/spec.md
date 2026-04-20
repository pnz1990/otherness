# Spec: Accessibility — axe assertions on Tier 1 pages

**Item**: issue-527
**Branch**: feat/issue-527

## Design reference

- **Design doc**: `docs/design/26-anchor-kro-ui.md`
- **Section**: `§ Future — Accessibility`
- **Implements**: Accessibility: run axe assertions on Tier 1 pages (RGD list, DAG, instance list, context switcher) (🔲 → ✅)

---

## Zone 1 — Obligations

**O1** — A Playwright journey must run axe-core WCAG 2.1 AA scans on all 4 Tier 1 pages: Catalog (RGD list), RGD DAG, instance list, context switcher (top bar).

Violation: Any of the 4 pages is missing from the journey.

**O2** — Critical and serious violations must fail CI. Minor/moderate must be informational only (logged, not blocking).

Violation: All violations block CI, or critical violations are swallowed.

**O3** — `@axe-core/playwright` must be added to `test/e2e/package.json`.

Violation: The dep is absent, causing `import AxeBuilder` to fail at runtime.

---

## Zone 2 — Implementer's judgment

- SVG DAG is excluded from axe scan (complex custom widget, manual audit separately).
- Context switcher step uses `.include()` to scope the scan to the top bar only.
- `test.skip` guards on `fixtureState.testAppReady` for steps requiring fixtures.

---

## Zone 3 — Scoped out

- Fixing existing axe violations (separate items opened from violation report)
- Running axe on Tier 2+ pages
- WCAG 2.2 tags (future item)
