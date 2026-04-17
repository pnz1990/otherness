# 03: Versioned Release Model

> Status: Planned — not yet started
> Applies to: otherness itself (not the projects it manages)
> Trigger: >10 repos using otherness, OR CRITICAL tier regression in production, OR community request

---

## What this does

Projects can pin to a stable otherness version and upgrade explicitly, rather than
always auto-updating to `main`. This prevents a bad agent instruction change from
immediately affecting all users.

Currently, every session runs `git -C ~/.otherness pull` at startup, taking the
latest `main`. This is the fast, zero-overhead default. Stage 5 adds an opt-in
stability layer on top of this default without removing it.

The versioning model:
- `main` remains the bleeding edge (current behavior, no change)
- Tags (`v1.0.0`, `v1.1.0`) mark stable release points
- Projects pin via `agent_version: v1.0.0` in `otherness-config.yaml`
- `/otherness.upgrade` shows changelog and upgrades the pin

---

## Present (✅)

*(Stage 5 has not started. Nothing is Present yet.)*

## Planned (🔲 — Stage 5 trigger required)

> ⚠️ These items are NOT queued by COORD until Stage 5 is explicitly triggered.
> Trigger criteria: >10 repos using otherness, OR CRITICAL tier regression in production, OR community request.
> See `docs/aide/progress.md §Stage 5 trigger criteria` for current status.

- 🔲 Git tags as releases — each stable release is tagged `vMAJOR.MINOR.PATCH` on the otherness repo
- 🔲 `agent_version` field in otherness-config.yaml — semver string; empty/absent = `main` (current behavior preserved)
- 🔲 Self-update respects version pin — `git -C ~/.otherness checkout <version>` instead of `pull` when `agent_version` is set
- 🔲 `/otherness.upgrade` command — shows changelog diff between current and latest tag, asks confirmation before updating the pin
- 🔲 CHANGELOG.md maintained automatically — each merged PR to main appends an entry (SM phase responsibility)

---

## Zone 1 — Obligations (when Stage 5 is implemented)

**O1 — Default behavior unchanged.**
Projects without `agent_version` set continue to auto-update to `main`. Adding a
version pin must be an explicit opt-in, not a change to the default.

**O2 — Upgrade is always explicit.**
No session silently upgrades the pinned version. `/otherness.upgrade` is the only
mechanism. It shows the diff and waits for confirmation.

**O3 — Pin is per-project, not global.**
`agent_version` lives in `otherness-config.yaml`, not in the agent files. Different
projects can pin to different versions.

**O4 — Rollback is documented.**
RECOVERY.md must include instructions for rolling back to a previous pin after a
bad upgrade.

---

## Zone 2 — Implementer's judgment

- Version numbering scheme: `v1.MINOR.PATCH`. Major version bump for breaking changes
  to CRITICAL tier files (standalone.md interface).
- Whether to backfill past releases with tags: at Stage 5 trigger, the first release
  is the current `main` HEAD tagged as `v1.0.0`.
- CHANGELOG format: minimal — one line per PR with type/scope and PR number.

---

## Zone 3 — Scoped out

- Automatic version discovery for projects (they must explicitly set `agent_version`)
- Multi-project version dashboard
- Pre-release tags (alpha, beta) — not needed at current scale
- Yanking / patching a released version (just release a new patch tag)

---

## Rejected alternatives

**"Always auto-update (current behavior, no versioning)."**
This is the current state and it works well at small scale. Stage 5 exists as a
future option, not a current need. See AGENTS.md §Future Risk: Global Deployment Model
for the full analysis of when to switch.

**"Each project forks the agent files."**
Defeats the network effect: improvements don't propagate. The whole point of otherness
is that a fix anywhere benefits everyone.
