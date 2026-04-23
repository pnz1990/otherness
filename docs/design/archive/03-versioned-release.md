# 03: Versioned Release Model

> Status: Active
> Applies to: otherness itself (not the projects it manages)

---

## What this does

Projects pin to a stable otherness version via `agent_version` and define an
`upgrade_policy` that controls which newer releases are adopted automatically.
The upgrade check runs in workflow Step 3 — before the agent starts — so the same
session gets the upgraded version, not the next one.

The versioning model:
- `main` remains the bleeding edge (empty `agent_version` = always pull latest)
- Tags (`v0.2.0`, `v0.3.0`) mark stable release points
- `agent_version: v0.2.0` pins to that exact release
- `upgrade_policy: "0.2.x"` allows auto-upgrade within the minor series
- `upgrade_policy: "0.x.x"` allows auto-upgrade to any new minor within the major
- Unset `upgrade_policy` with a set `agent_version` = never auto-upgrade (fully pinned)

The policy is evaluated at Step 3 of the scheduled workflow, not by the agent.
If a newer release matches the policy, Step 3 checks it out and rewrites
`agent_version` in `otherness-config.yaml` before the agent starts. The agent
wakes up on the new version. The config change is committed as part of the
session's normal state write at batch end.

---

## Present (✅)

- ✅ `agent_version` field in otherness-config.yaml — semver string; empty/absent = latest (standalone.md SELF-UPDATE + otherness-config-template.yaml, 2026-04-18)
- ✅ Self-update respects version pin — standalone.md SELF-UPDATE block: `git checkout <version>` when agent_version set (standalone.md, 2026-04-18)
- ✅ Git tags established — `v0.1.0` and `v0.2.0` tags exist; tagging pattern in use
- ✅ `upgrade_policy` field + Step 3 auto-upgrade — workflow reads policy, finds newest matching tag, checks it out and rewrites agent_version before agent starts (2026-04-20)

## Future (🔲)

- ✅ CHANGELOG.md maintained automatically — each merged PR appends an entry (SM phase) (PR #729, 2026-04-21)
- ✅ `/otherness.upgrade` interactive command updated to respect upgrade_policy — Step 1 now reads and displays `upgrade_policy` from `otherness-config.yaml`, explains what the policy allows (major/minor/patch wildcard), warns when policy is unset; Step 2 filters available releases to show only those matching the policy (PR #770, 2026-04-21)

---

## Zone 1 — Obligations

**O1 — Default behavior unchanged.**
Projects without `agent_version` set continue to pull `main`. Adding a pin is explicit.

**O2 — The upgrade check runs before the agent, not during.**
`upgrade_policy` is evaluated in workflow Step 3 (bash, no LLM). The session that
triggers the check runs on the new version immediately. SM never manages this.

**O3 — `upgrade_policy` absence means no auto-upgrade.**
A project with `agent_version` set but no `upgrade_policy` is fully pinned. It only
moves when a human or the auto-release bump PR updates `agent_version` explicitly.

**O4 — Major version boundary is never crossed automatically.**
`upgrade_policy: "0.x.x"` allows any `0.*.*` release. It will never advance to `1.0.0`.
The major digit is a hard stop regardless of the policy pattern.

**O5 — The agent_version rewrite is committed.**
After Step 3 upgrades the version, the new `agent_version` value is written back to
`otherness-config.yaml` and committed at batch end via the session branch PR (SM §4g).
The upgrade is permanent and auditable — not a transient runtime decision.

---

## Zone 2 — Implementer's judgment

- Policy matching uses simple prefix comparison on the semver string, not regex.
  `0.2.x` matches any tag starting with `v0.2.`. `0.x.x` matches any tag starting
  with `v0.`. This is intentionally simple — no semver library needed.
- Tag discovery: `git -C ~/.otherness tag --sort=-version:refname` returns all tags
  newest-first. The first match wins.
- If the checkout fails (tag doesn't exist locally after fetch): stay on current version,
  log a warning, continue. Never fail the session over a version upgrade attempt.

---

## Zone 3 — Scoped out

- Pre-release tags (alpha, beta) — not needed at current scale
- Yanking / patching a released version (just release a new patch tag)
- Per-file versioning (the whole agent set is one version)
