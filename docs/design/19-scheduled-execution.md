# 19: Scheduled Execution — The Loop That Never Needs You to Press Play

> Status: Active | Created: 2026-04-19 | Updated: 2026-04-19
> Applies to: otherness itself and all managed projects

---

## The problem this solves

When the conversation ends, the loop stops. A local persistent process solves nothing
— it dies when the machine sleeps, the terminal closes, or the user logs out.

The loop is only genuinely eternal if it runs on infrastructure that does not depend
on a human-initiated session. That infrastructure is GitHub Actions with a schedule
trigger.

---

## The mechanism

OpenCode has a native GitHub Actions integration (`anomalyco/opencode/github@latest`)
that supports `schedule` events. A cron workflow checks out the repo, runs OpenCode
with the `/otherness.run` prompt, and exits. The next cron trigger does the same.

The loop runs every N hours. No human required.

---

## Credential model

**The workflow uses Bedrock via OIDC — no stored API keys.**

AWS credentials are obtained at runtime by assuming an IAM role via GitHub's OIDC
token. No `ANTHROPIC_API_KEY` or `AWS_ACCESS_KEY_ID` is stored anywhere. The IAM
role (`github-bedrock-key`) is scoped to the `pnz1990/*` GitHub org and grants only
`bedrock:InvokeModel` and related read permissions.

This is required for Amazon internal accounts (Isengard). Long-lived IAM user keys
in Isengard accounts trigger the Amazon key rotation campaign and generate security
findings. OIDC is the policy-compliant mechanism.

```yaml
- name: Configure AWS credentials (Bedrock via OIDC)
  uses: aws-actions/configure-aws-credentials@v4
  with:
    role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
    role-session-name: otherness-bedrock
    aws-region: us-east-1
```

**Three secrets are required per repo:**

| Secret | Value | Purpose |
|--------|-------|---------|
| `AWS_ROLE_ARN` | `arn:aws:iam::569190534191:role/github-bedrock-key` | OIDC role for Bedrock |
| `AWS_ACCOUNT_ID` | `569190534191` | Account reference |
| `AWS_DEFAULT_REGION` | `us-east-1` | Bedrock region |

Run `scripts/setup-github-bedrock-key.sh --update-secrets owner/repo` to push all
three to a new project repo.

---

## GitHub token model

**The workflow uses a PAT (`GH_TOKEN`), not `GITHUB_TOKEN`.**

`GITHUB_TOKEN` (the built-in Actions token) intentionally cannot trigger other
workflows when it pushes commits. This means: the agent merges a PR, the CI workflow
does not run, the agent thinks CI passed because nothing ran. That is a silent failure.

A PAT stored as `GH_TOKEN` does not have this restriction. Pushes from a PAT trigger
other workflows normally.

The PAT must have `repo` and `workflow` scopes.

The workflow uses `GH_TOKEN` for:
- `actions/checkout` `token:` — so pushes from the checkout trigger CI
- `gh auth login` — so the `gh` CLI uses the full PAT
- `GITHUB_TOKEN` env override in the OpenCode step — so all GitHub API calls use the PAT

```yaml
- uses: actions/checkout@v4
  with:
    token: ${{ secrets.GH_TOKEN }}

- name: Authenticate gh CLI
  env:
    GH_TOKEN: ${{ secrets.GH_TOKEN }}
  run: |
    echo "$GH_TOKEN" | gh auth login --with-token
    gh auth setup-git

- name: Run otherness
  uses: anomalyco/opencode/github@latest
  env:
    GH_TOKEN:     ${{ secrets.GH_TOKEN }}
    GITHUB_TOKEN: ${{ secrets.GH_TOKEN }}
```

---

## Required job permissions

```yaml
permissions:
  id-token: write        # AWS OIDC token exchange
  contents: write        # push commits, create/merge branches
  pull-requests: write   # open/update/merge PRs, post review comments
  issues: write          # create/label/close issues, post comments
  actions: write         # trigger other workflows programmatically
  statuses: write        # post commit statuses
```

`id-token: write` is required for OIDC. Without it, the `configure-aws-credentials`
step fails with a permissions error. All others are required for the agent to operate
its full loop.

---

## Git identity

The workflow sets a bot identity so commits are clearly machine-generated:

```yaml
- name: Configure git identity
  run: |
    git config --global user.name  "otherness[bot]"
    git config --global user.email "otherness[bot]@users.noreply.github.com"
```

---

## Per-project cron configuration

The cadence is set in two places that must stay in sync:

1. **The workflow file** — the `cron:` value under `on.schedule`
2. **`otherness-config.yaml`** — the `schedule.cron` field (read by the agent to
   report cadence in health signals)

```yaml
# otherness-config.yaml
schedule:
  cron: "0 * * * *"    # every hour — kardinal-promoter
  model: amazon-bedrock/global.anthropic.claude-sonnet-4-6
```

Reference cadences:

| Project type | Cron | Rationale |
|---|---|---|
| Active development | `0 * * * *` | Every hour — kardinal-promoter |
| Self-improvement | `0 */6 * * *` | Every 6 hours — otherness itself |
| Standby / low-churn | `0 */12 * * *` | Every 12 hours |

The cron in the workflow file is the authoritative source. `otherness-config.yaml`
is informational (used by the agent for reporting). If they disagree, the workflow
file wins.

---

## The full workflow template

```yaml
name: otherness scheduled run

on:
  schedule:
    - cron: "0 */6 * * *"   # override per project
  workflow_dispatch:

jobs:
  otherness:
    runs-on: ubuntu-latest
    permissions:
      id-token: write
      contents: write
      pull-requests: write
      issues: write
      actions: write
      statuses: write

    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0
          token: ${{ secrets.GH_TOKEN }}

      - name: Configure git identity
        run: |
          git config --global user.name  "otherness[bot]"
          git config --global user.email "otherness[bot]@users.noreply.github.com"

      - name: Install otherness agent files
        run: git clone --quiet --depth 1 https://github.com/pnz1990/otherness.git ~/.otherness

      - name: Sync otherness command files
        run: |
          mkdir -p .opencode/command
          for src in ~/.otherness/.opencode/command/otherness.*.md; do
            [ -f "$src" ] || continue
            fname=$(basename "$src"); dest=".opencode/command/$fname"
            if ! cmp -s "$src" "$dest" 2>/dev/null; then cp "$src" "$dest"; fi
          done

      - name: Configure AWS credentials (Bedrock via OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_ARN }}
          role-session-name: otherness-bedrock
          aws-region: us-east-1

      - name: Authenticate gh CLI
        env:
          GH_TOKEN: ${{ secrets.GH_TOKEN }}
        run: |
          echo "$GH_TOKEN" | gh auth login --with-token
          gh auth setup-git

      - name: Run otherness
        uses: anomalyco/opencode/github@latest
        env:
          AWS_REGION:   us-east-1
          GH_TOKEN:     ${{ secrets.GH_TOKEN }}
          GITHUB_TOKEN: ${{ secrets.GH_TOKEN }}
        with:
          model: amazon-bedrock/global.anthropic.claude-sonnet-4-6
          prompt: |
            AGENTS_PATH=$(python3 -c "
            import re, os
            section = None
            for line in open('otherness-config.yaml'):
                s = re.match(r'^(\w[\w_]*):', line)
                if s: section = s.group(1)
                if section == 'maqa':
                    m = re.match(r'^\s+agents_path:\s*[\"\'']?([^\"\'#\n]+)[\"\'']?', line)
                    if m: print(os.path.expanduser(m.group(1).strip())); break
            " 2>/dev/null || echo "$HOME/.otherness/agents")

            Read and follow $AGENTS_PATH/standalone.md.
```

---

## What changes when this runs on a schedule vs a human session

**Same:** The agent loop is identical. It reads state.json, claims items, implements,
runs QA, merges, reports health signal. Every phase runs the same way.

**Different:** The session is bounded. A GitHub Actions runner has a 6-hour job
timeout. The agent loop should detect this and write a clean handoff to `_state`
before the runner terminates. Batches complete fully; the runner exits; the next
schedule trigger picks up where the handoff says.

This is already handled: the SM phase writes a session handoff to `_state` after every
batch. The next session reads it and resumes cleanly. The distributed lock protocol
(`feat/<item>` branch) prevents two parallel runners from claiming the same item.

---

## Deploying to a new managed project

1. Run `scripts/setup-github-bedrock-key.sh --update-secrets owner/repo` — pushes
   `AWS_ROLE_ARN`, `AWS_ACCOUNT_ID`, `AWS_DEFAULT_REGION`
2. Add `GH_TOKEN` secret to the repo (PAT with `repo` + `workflow` scopes)
3. Copy `.github/workflows/otherness-scheduled.yml` from the otherness template;
   set the `cron:` value for the project's desired cadence
4. Update `otherness-config.yaml` `schedule.cron` to match
5. Trigger `workflow_dispatch` once to verify the run completes before relying on cron

See `docs/design/13-scheduled-execution.md` on each managed project for the
project-specific deployment record.

---

## Present (✅)

- ✅ `.github/workflows/otherness-scheduled.yml` — cron (0 */6 * * *) + workflow_dispatch; Bedrock via OIDC; GH_TOKEN PAT for push/PR/trigger; all required permissions (2026-04-19)
- ✅ `otherness-config.yaml` — `schedule.cron`, `schedule.model`, `schedule.api_key_secret` fields (2026-04-19)
- ✅ `otherness-config-template.yaml` — `schedule` section with setup instructions (2026-04-19)
- ✅ `scripts/validate.sh` — checks scheduled workflow exists when `schedule.cron` is set (2026-04-19)
- ✅ `scripts/setup-github-bedrock-key.sh` — idempotent OIDC setup: creates provider, IAM role, Bedrock policy, pushes secrets to GitHub (2026-04-19)
- ✅ IAM OIDC provider `token.actions.githubusercontent.com` in account 569190534191 — trust scoped to `pnz1990/*` (2026-04-19)
- ✅ IAM role `github-bedrock-key` — OIDC trust for `pnz1990/*`, inline `BedrockInvoke` policy (2026-04-19)
- ✅ kardinal-promoter deployed — hourly cron, all secrets set, PR #828 (2026-04-19)

## Future (🔲)

- 🔲 `/otherness.setup` and `/otherness.onboard`: add "activate scheduled loop" section that runs `setup-github-bedrock-key.sh` and copies the workflow template automatically — currently requires manual steps
- 🔲 `scripts/validate.sh`: verify `GH_TOKEN` secret exists on the repo when `schedule.cron` is configured (currently only checks for the workflow file)
- 🔲 Token expiry detection: if `GH_TOKEN` PAT expires, the workflow fails silently on push; add a preflight step that validates the token has required scopes and posts a `[NEEDS HUMAN]` issue on failure

---

## Zone 1 — Obligations

**O1 — Use Bedrock OIDC, never stored AWS keys.**
Long-lived IAM user keys in Isengard-managed accounts are a policy violation.
OIDC is the only compliant mechanism. `setup-github-bedrock-key.sh` is the
authoritative setup tool. Do not create IAM users with access keys for this purpose.

**O2 — Use `GH_TOKEN` PAT, not `GITHUB_TOKEN`, for checkout and gh CLI.**
`GITHUB_TOKEN` pushes do not trigger other workflows. The agent's CI loop depends
on CI running after merges. Using `GITHUB_TOKEN` breaks the CI gate silently.

**O3 — All six permissions must be granted.**
`id-token`, `contents`, `pull-requests`, `issues`, `actions`, `statuses` — all write.
Removing any one breaks a specific agent capability. The set is minimal and correct.

**O4 — `workflow_dispatch` is always included.**
Manual testing and on-demand runs must be possible without waiting for cron.

**O5 — Cron in workflow file and `schedule.cron` in config must match.**
The workflow file is authoritative. The config field is used by the agent for
reporting. Drift between them produces incorrect health signals.

---

## Zone 2 — Implementer's judgment

- Runner type: `ubuntu-latest` is correct. No special hardware needed.
- `fetch-depth: 0` is required so the agent can read full git history for state.
- Whether to pin `actions/checkout` and `configure-aws-credentials` to SHAs:
  recommended for production hardening but not required for current usage.
- Model selection: `amazon-bedrock/global.anthropic.claude-sonnet-4-6` unless
  `schedule.model` in config overrides it.

---

## Zone 3 — Scoped out

- Multi-repo orchestration from a single workflow (each project has its own workflow)
- Parallel runners (the distributed lock handles collision; multiple runners waste tokens)
- Cost management / token budgeting (future: token-spent counter in state.json)
- Automatic PAT rotation (out of scope; PATs are long-lived by design here)
