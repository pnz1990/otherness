# Spec: issue-810 — Workflow-level silent failure detection

## Design reference
- **Design doc**: `docs/design/19-scheduled-execution.md`
- **Section**: `§ Future (line 293)`
- **Implements**: Workflow-level silent failure detection — pre-flight "session started" comment (🔲 → ✅)

---

## Zone 1 — Obligations (falsifiable)

1. **O1**: `otherness-scheduled.yml` must contain a step that executes BEFORE the "Run otherness" step (Step 8) that posts a comment to the report issue using `GITHUB_TOKEN` (not `GH_TOKEN`).

2. **O2**: The comment body must contain "🔄 Session started —" followed by a UTC timestamp in ISO 8601 format (YYYY-MM-DDTHH:MM:SSZ or equivalent).

3. **O3**: The step must use `GITHUB_TOKEN` (GitHub Actions built-in) not `GH_TOKEN` (user-configured PAT) — so it works even when `GH_TOKEN` is misconfigured.

4. **O4**: The step must be `continue-on-error: true` — a comment failure must NOT block the main agent run.

5. **O5**: The step must read `REPORT_ISSUE` from `otherness-config.yaml` and only post if the value is a valid positive integer ≥ 1. If unreadable or 0, skip silently.

6. **O6**: The step must NOT use `GH_TOKEN` — it must use only `GITHUB_TOKEN` (job permission-scoped). This is the key design doc requirement: proves the runner started even if `GH_TOKEN` is invalid.

7. **O7**: The design doc also requires PM §5 to detect stale `_state` + missing "session started" comment (>12h on hourly cron). This PM detection is scoped out — tracked as a separate future item.

---

## Zone 2 — Implementer's judgment

- Step placement: after Step 6 (gh CLI auth) and before Step 7 (Vision scan), so the heartbeat fires even if vision scan fails.
- Use `gh issue comment` with `GITHUB_TOKEN` set explicitly (not inherited).
- Timestamp format: `$(date -u +%Y-%m-%dT%H:%M:%SZ)` for bash compatibility.
- REPORT_ISSUE parsing: same python3 one-liner as used in standalone.md startup.

---

## Zone 3 — Scoped out

- PM §5 detection of missing "session started" comment (tracked separately in design doc 19)
- Multi-repo: this change only applies to `otherness-scheduled.yml` in this repo; template propagation is a separate concern
- "Session ended" heartbeat (different pattern; out of scope)
