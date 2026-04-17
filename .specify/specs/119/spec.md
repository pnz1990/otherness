# Spec: Intent-Based Queue / Capability Profiles (#119)

## Zone 1 — Obligations (falsifiable)

### O1: Capability profile read from config
`standalone.md` startup reads the `agents` section of `otherness-config.yaml` to find a
matching profile for the current session (matched by `REPO_NAME` hostname or the first entry),
and sets `ALLOWED_AREAS` from that profile's `areas` list.
- **Violation**: `ALLOWED_AREAS` is always empty regardless of what is in `otherness-config.yaml`.

### O2: Fallback — no profile or no areas match
If no capability profile is found, or if `areas` is empty/absent, `ALLOWED_AREAS` is unset
(agent claims any item). Same as current behavior.
- **Violation**: Agent gets stuck with `ALLOWED_AREAS` set to an empty value and claims nothing.

### O3: Acceptance test passes
```bash
grep -c "capability\|agent.*profile\|ALLOWED_AREAS" ~/.otherness/agents/standalone.md  # ≥ 1
```

### O4: JOB_FAMILY respected per profile
If a capability profile specifies `job_family`, it overrides the default `JOB_FAMILY` read from
`otherness-config.yaml` `project.job_family`.
- **Violation**: `JOB_FAMILY` is always the project-level value even when a per-agent profile specifies a different one.

---

## Zone 2 — Implementer's judgment

- How to select which profile applies to this session (first match, or by `id` from env var).
- Exact YAML structure for the `agents:` section (follow the example in the issue body).
- Whether to log the selected profile at startup.

---

## Zone 3 — Scoped out

- Dynamic profile switching mid-session.
- Profile-based rate limiting or resource quotas.
- Profile validation (schema check of otherness-config.yaml).
- Deprecating bounded-standalone.md — not changed here.

---

## Design reference
- N/A — pre-DDDD item (written before design doc system, PR #144)
