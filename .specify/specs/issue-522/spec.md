# Spec: Playwright integration in PDCA — first 3 UI scenarios

**Item**: issue-522
**Branch**: feat/issue-522

## Design reference

- **Design doc**: `docs/design/25-anchor-kardinal-promoter.md`
- **Section**: `§ Future — Playwright integration in PDCA`
- **Implements**: Playwright integration in PDCA — first 3 UI scenarios (bundle status, pipeline graph, rollback button) (🔲 → ✅)

---

## Context

`pnz1990/kardinal-promoter` already has a Playwright test suite at `web/test/e2e/journeys/` (journeys 001–010) and a mock server at `web/test/e2e/mock-server/server.mjs`. These tests run in `e2e.yml` (Go-based e2e) and via `npm run test:e2e` in the `web/` directory, but they do **not** run inside the PDCA workflow.

The design doc §O2 requires Playwright to be added to PDCA before UI scenarios can be validated as anchor coverage. The mock server provides deterministic fixture data — no real Kubernetes cluster is needed.

This item:
1. Adds PDCA steps S25–S27 that run Playwright journeys 001, 002, 011 against the mock server
2. Creates journey `011-rollback-button.spec.ts` (the rollback UI scenario is not yet covered)
3. Reports S25–S27 pass/fail in the PDCA anchor comment

---

## Zone 1 — Obligations

**O1** — The PDCA workflow (`pnz1990/kardinal-promoter/.github/workflows/pdca.yml`) must contain a step that installs Node.js and Playwright, starts the mock server, runs at least 3 Playwright journey specs, and captures pass/fail counts.

Violation: PDCA produces an anchor comment with no S25–S27 entries.

**O2** — Journey 011 (`web/test/e2e/journeys/011-rollback-button.spec.ts`) must assert that the rollback button is present and clickable in the UI, and that the mock server responds with `{ message: 'rollback started' }`.

Violation: The journey does not call the rollback endpoint or does not check the button is visible.

**O3** — The PDCA anchor comment must include S25, S26, and S27 lines matching the format `✅ S25: ...`, `✅ S26: ...`, `✅ S27: ...` (or `❌` on failure).

Violation: PDCA comment contains S25–S27 with no status prefix.

**O4** — The Playwright step must not require a real Kubernetes cluster. It runs against the mock server only. The `webServer` config in `playwright.config.ts` already handles mock server startup.

Violation: The PDCA step makes a `kubectl` call inside the Playwright execution.

**O5** — The Playwright step must use `npm ci --prefix web` and `npx --prefix web playwright install chromium --with-deps` for reproducible installs.

Violation: Steps use `npm install` instead of `npm ci`, or install all browsers instead of chromium-only.

---

## Zone 2 — Implementer's judgment

- Whether to add the Playwright step as a separate PDCA job or an additional step in the existing `pdca` job: use an additional step in the existing job to keep scenario numbering and the anchor comment generation in one place.
- Which 3 journeys to run: 001 (pipeline list → bundle status), 002 (DAG node click → pipeline graph), 011 (rollback button). This maps directly to the design doc's "bundle status, pipeline graph, rollback button".
- Playwright test output parsing: use `playwright test --reporter=line` exit code only (0 = all pass, non-zero = failure). Count each journey file as one scenario.

---

## Zone 3 — Scoped out

- Running all 10+ existing journeys in PDCA (adds ~5min; out of scope for this item)
- Adding Playwright to the CI or e2e.yml workflow (already present in e2e.yml)
- UI test against a real cluster (requires a web server in the controller — future item)
- Journey 009 (accessibility axe-core) in PDCA (separate size/m item)
