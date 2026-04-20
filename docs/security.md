# Security — What Is Mitigated and What Is Not

otherness executes AI-generated code with full bash access, holds write credentials to
your repositories, and runs on a schedule without a human in the loop. This document
describes the real security posture — what is actually protected and what residual risk
you are accepting.

The full technical threat model, attack vectors, and mitigation design is in
**[docs/design/27-security-model.md](./docs/design/27-security-model.md)**.
This document is the operational summary. When they conflict, the design doc is authoritative.

---

## What is mitigated

### Supply chain: action SHAs pinned (M1) ✅

All GitHub Actions used in the workflow are pinned to exact commit SHAs, not floating
version tags. A compromised action repository cannot silently change what executes in
your workflow. SHA updates are reviewed as security changes.

### Supply chain: otherness clone pinned (M2) ✅

The otherness repo is cloned and then checked out to a specific SHA set in
`otherness-config.yaml` under `agent_version`. A compromise of the otherness repo
cannot propagate to your project until you update `agent_version` and review the change.

**This is only effective if `agent_version` is set.** If it is not set, the clone runs
at HEAD and this mitigation does not apply.

### Token scope: GitHub App (M3) ✅ when configured

When `OTHERNESS_USE_APP_TOKEN=true` and `APP_ID`/`APP_PRIVATE_KEY` secrets are configured,
the agent uses a per-repository installation token that:
- Is scoped to one repository only
- Expires after one hour (auto-rotated)
- Cannot be used to access other repositories
- Is attributed to the App installation in audit logs

**This is only effective if the GitHub App is configured.** The PAT fallback is described
below under residual risks.

### Workflow modification blocked (M4) ✅

The job's `permissions:` block intentionally omits `actions: write`. The agent cannot
trigger other workflows via the Actions API. It triggers CI by pushing commits, which
fires push-triggered workflows automatically — no API call needed.

### agents_path injection blocked (M6) ✅

Before executing any agent, the workflow validates that `agents_path` (resolved from
`otherness-config.yaml`) is within `~/.otherness`. A tampered config file cannot
redirect the agent to attacker-controlled instruction files.

### AGENTS.md changes require collaborator review (M8) ✅

The `otherness-security-checks.yml` workflow runs on every PR. If `AGENTS.md` is
modified by a non-collaborator, CI fails. AGENTS.md is the highest-impact prompt
injection surface — this check prevents external contributors from injecting
malicious instructions via PR.

### Issue queue restricted to collaborators (M10) ✅

The same security checks workflow detects when the `otherness` label is applied to an
issue by a non-collaborator and removes it. External users cannot inject items into the
agent's work queue by creating labeled issues.

### AWS credentials: OIDC only, 1-hour expiry ✅

No AWS credentials are stored anywhere. The OIDC token exchange issues a session token
at runtime that expires after one hour. A stolen token has a 1-hour window.

### AWS spend: Budget alert ✅

An AWS Budget alert fires at abnormal daily Bedrock spend. Runaway token consumption
(from prompt poisoning or model misbehavior) triggers an alert before it becomes a
significant financial event.

---

## Residual risks you are accepting

These are not fully closed. You must consciously accept them or mitigate them yourself.

### PAT fallback has cross-repo blast radius ⚠️

If the GitHub App is not configured and you are using `GH_TOKEN` (PAT), the token
has `repo+workflow` scope on **all repositories you own**, not just the one otherness
manages. A compromised agent session on one project could push to, modify, or trigger
workflows on all your other projects.

**To close this**: configure the GitHub App (M3). This scopes the token to one repo.
See `onboarding-new-project.md §9b` for setup instructions.

### _state branch writable by any collaborator ⚠️

The `_state` branch has force-push and deletion blocked, but any repository collaborator
can push directly to it. A malicious or compromised collaborator could inject items into
the agent queue or corrupt session state.

**Fully closing this requires either**: (a) GitHub Enterprise's branch restriction feature
to restrict push to specific actors, or (b) configuring the GitHub App (M3) and relying
on the fact that only the App identity has a legitimate reason to push to `_state`.
On free/standard GitHub, this risk is partially open.

### bash:allow with credentials in environment ⚠️ (accepted design tradeoff)

The agent runs with `bash:allow`. Any bash command it executes has access to `GH_TOKEN`,
the AWS session credentials, and any other environment variables present. This is required
for the agent to function — it cannot push commits or call the GitHub API without it.

The blast radius is reduced by M3 (scoped App token), M1 (pinned supply chain), and M2
(pinned agent version). It is not eliminated.

### No network egress restriction ⚠️ (known gap, GitHub platform limitation)

The agent can make outbound HTTP calls to any host. There is no firewall rule preventing
exfiltration of credentials to an external endpoint. On public GitHub Actions (free/pro
plans), network egress filtering is not available. On GitHub Enterprise or self-hosted
runners, you can add egress filtering.

**This is a real risk.** The defense is the supply chain controls (M1, M2) which prevent
attacker-controlled instructions from reaching the agent. If those controls hold, this
surface is not exposed.

---

## Token setup decision

| Your situation | Recommended approach |
|---|---|
| Personal project, only repo you own | PAT is acceptable. Risk is low (only your repos at risk). |
| Multiple repos owned, one compromised exposes others | Configure GitHub App. Cross-repo blast radius is unacceptable. |
| Team repo, multiple collaborators | Configure GitHub App. Shared PAT is a credential hygiene issue. |
| Sensitive code (credentials, customer data) | GitHub App mandatory. Review egress options. |

---

## Hardening checklist

Before running otherness on a production or sensitive project:

```
□ agent_version set in otherness-config.yaml (M2 — 3B closed)
□ GitHub App configured: OTHERNESS_USE_APP_TOKEN=true + APP_ID + APP_PRIVATE_KEY (M3 — 3E/4C closed)
□ All workflow actions SHA-pinned — verify in otherness-scheduled.yml (M1 — 3A closed)
□ _state branch: force-push and deletion blocked (M7 — partial on free plan)
□ Branch protection on main requires PR review
□ AGENTS.md is in "Files Agents Must Not Modify" in AGENTS.md
□ Report issue subscribed — you receive [NEEDS HUMAN] notifications
□ AWS Budget alert configured for abnormal Bedrock spend (M5)
□ Read docs/design/27-security-model.md for the full attack vector analysis
```

---

## Incident response

If you suspect a compromise (unexpected pushes, unexpected external HTTP calls in logs,
unexpected AWS API calls):

1. **Rotate immediately, before confirming.** Run `gh secret set GH_TOKEN` with a new PAT.
   If using GitHub App, revoke the App's private key and generate a new one.
2. Disable the scheduled workflow: `gh workflow disable otherness-scheduled.yml --repo your-org/your-repo`
3. Review GitHub Actions run logs for the suspicious period (Actions → Workflow runs)
4. Review the `_state` branch git log for unexpected commits
5. Re-enable only after rotating all credentials and understanding the root cause
