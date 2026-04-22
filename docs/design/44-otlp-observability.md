# 44: Observability — Enterprise-Grade Telemetry for Autonomous Development

> Status: Active | Revised: 2026-04-21
> Applies to: all projects managed by otherness
> OpenCode versions: experimental.openTelemetry since v1.4.0; OTEL_RESOURCE_ATTRIBUTES since v1.14.17

---

## The enterprise problem

An autonomous development system running 24/7 on infrastructure is not a web server.
The observability questions enterprises ask are different:

| Role | Question |
|---|---|
| **Platform engineering** | Which projects are healthy? Which are stalled? What is the fleet-wide session success rate this week? |
| **FinOps / cost governance** | How much did each project spend on LLM tokens this month? Which team owns the spike on April 15? |
| **Security / compliance** | What did the agent do between 02:00 and 04:00 UTC on Thursday? Is there an immutable record I can show an auditor? |
| **SRE / on-call** | Session duration p99 is 58 minutes. The OIDC token expires at 60. Alert me before it breaks again. |
| **Engineering manager** | Are my 3 projects making meaningful progress every run, or are they spinning on chores? |

None of these are answered by "I have a trace in Honeycomb." They require a
structured observability strategy with four distinct layers.

---

## The four-layer observability model

```
Layer 4: Fleet intelligence    — cross-project health, comparative velocity
Layer 3: Cost governance       — token spend, budget alerts, per-project chargebacks
Layer 2: Security audit log    — immutable record of every agent action
Layer 1: Session telemetry     — per-session traces and metrics (OTLP)
```

Each layer is independent. Layer 1 requires an OTLP backend. Layers 2–4
require additional otherness-side instrumentation that does not depend on
a customer-operated backend.

---

## Layer 1: Session telemetry (OTLP)

**What it is**: OpenCode exports AI SDK telemetry spans via OTLP. One span per LLM
call (model, input tokens, output tokens, latency, finish reason), one span per tool
invocation (tool name, duration). Resource tags identify project, session, batch, step.

**Who it's for**: Individual project owners who want to understand session performance.
Optional. Zero config = zero telemetry.

**What signals are available:**

| Metric / Trace | What you learn |
|---|---|
| `ai.generateText` span | LLM call latency, token counts, finish reason per call |
| `ai.toolCall` span | Which tools are slow? `gh api` rate-limit waits, large reads |
| Session root span | Total duration, step (vision-scan vs run), batch number |
| Token rate (derived) | Input + output tokens per session, per step, per model |
| Session duration histogram | p50/p95/p99 across all sessions for a project |

**OTLP signals:**
- **Traces** → AWS X-Ray, Grafana Tempo, Jaeger, Honeycomb (per-session detail, debugging)
- **Metrics** → Amazon Managed Prometheus, Grafana Mimir, Prometheus (aggregates, histograms)

Prometheus (since v2.47) accepts OTLP metrics at `/api/v1/otlp/v1/metrics` — time-series
aggregates (token/hour, session count, p99 latency). For the full span tree, use a tracing
backend.

**Recommended AWS stack** (zero new infrastructure — extends the existing OIDC role):
```
OpenCode session
  ├── OTLP traces  ──→ AWS X-Ray         (per-session span tree, debugging)
  └── OTLP metrics ──→ Amazon Managed    (trends, token/hour, p99 histograms)
                        Prometheus (AMP)
                        └── Amazon Managed Grafana (unified dashboard)

IAM additions to existing OIDC role:
  xray:PutTraceSegments, xray:PutTelemetryRecords
  aps:RemoteWrite
```

**Recommended non-AWS stack:**
```
Grafana Cloud (single platform for traces + metrics + logs)
  ├── Traces: Grafana Tempo
  ├── Metrics: Grafana Mimir (Prometheus-compatible)
  └── Logs: Grafana Loki
Free tier: 50GB traces, 10K metrics series, 50GB logs/month
```

**Configuration** (opt-in, per-project):
```yaml
# otherness-config.yaml
observability:
  otlp:
    enabled: false          # default: false — no telemetry without this
    backend: aws-xray       # aws-xray | grafana | prometheus | custom
    service_name: otherness # OTEL service.name tag
    # For custom or grafana backends:
    endpoint_secret: OTEL_EXPORTER_OTLP_ENDPOINT   # GitHub secret name
    headers_secret:  OTEL_EXPORTER_OTLP_HEADERS    # GitHub secret name
    # For aws-xray: no secrets needed — OIDC role handles auth
```

---

## Layer 2: Security audit log

**What it is**: An immutable, structured log of every significant agent action.
Not traces — traces are sampling-based and show performance. This is a security
control: every file write, every `git push`, every PR merge, every issue created,
timestamped and signed, with the session ID and batch number that caused it.

**Who it's for**: Security teams, compliance officers, regulated industries (finance,
healthcare, government). Required for SOC2 Type II, ISO 27001, and many enterprise
procurement requirements.

**What it records:**
```
{
  "timestamp": "2026-04-21T14:32:07Z",
  "session_id": "sess-abc123",
  "batch": 47,
  "project": "pnz1990/kro-ui",
  "actor": "otherness-app[bot]",
  "action": "git.push",
  "target": "refs/heads/feat/issue-578",
  "sha_before": "abc1234",
  "sha_after": "def5678",
  "files_changed": 3,
  "item_id": "issue-578"
}
```

Actions logged:
- `git.push` — every branch push, with before/after SHA
- `pr.create` — every PR opened
- `pr.merge` — every PR merged, with review bypass (--admin) noted
- `issue.create` — every issue created
- `issue.close` — every issue closed
- `file.write` — every file written (path only, not content)
- `branch_protection.clear` — every time QA clears branch protection (high-risk)
- `secret.read` (future) — if the agent reads secrets from the env

**Storage options:**
- **AWS CloudTrail** — GitHub Actions events are already in CloudTrail if your org
  uses AWS. The audit log is immutable, encrypted, and 90-day retention by default.
  The agent also writes to an S3 audit bucket via the OIDC role.
- **GitHub Audit Log** — GitHub's own audit log captures every API call made with
  the App token. Available in the GitHub Enterprise or Org audit log API.
- **OpenSearch / Elasticsearch** — self-hosted, full-text searchable, long retention.

**Implementation**: SM §4a posts a structured JSON audit event to the configured
sink after every significant operation. The event is signed with the session's
OIDC token claim (verifiable without contacting the agent).

---

## Layer 3: Cost governance

**What it is**: Per-project LLM spend tracking with budget alerts, anomaly detection,
and chargeback reporting. Enterprise platform teams need to allocate AI costs to
business units and prevent runaway spend.

**Why the current approach is insufficient**: The existing AWS Budget alert fires at
an absolute daily threshold for the entire account. It doesn't distinguish which
project caused a spike, doesn't alert on per-session anomalies, and can't do
chargebacks.

**The enterprise model:**

```
Project-level cost tags (via OTEL_RESOURCE_ATTRIBUTES):
  project=pnz1990/kro-ui, team=platform, cost_center=PLAT-001

AWS Cost Allocation Tags on Bedrock calls:
  otherness:project, otherness:session, otherness:batch

Per-project budget alerts:
  $50/day per project (not per account)
  Alert at 70% consumption
  Hard stop at 100% (SM reads budget status before claiming items)

Monthly chargeback report:
  SM §4a generates a cost report at month boundary
  Format: project | total_tokens | estimated_cost | session_count
  Posted to the project's report issue and to a central cost Slack channel
```

**Token counting** (available from AI SDK spans):
- Input tokens × model input price per 1K = input cost
- Output tokens × model output price per 1K = output cost
- Model price table maintained in `otherness-config.yaml` or fetched from Bedrock API

**Anomaly detection threshold**: if a single session consumes >3× the project's
30-day rolling average token count, SM opens a `[COST ANOMALY]` issue and pauses
the loop until a human reviews. Potential causes: prompt injection, infinite loop,
massive feature (expected), model switch (expected).

---

## Layer 4: Fleet intelligence

**What it is**: A cross-project health and velocity view for teams running otherness
on multiple projects. The SM cross-project monitoring already exists (§4a) but it
reports health in binary terms (alive/stalled). Fleet intelligence adds comparative
velocity, trend analysis, and proactive recommendations.

**Who it's for**: Engineering managers, platform teams, and technical leads who own
multiple projects on otherness.

**What it shows:**

```
Fleet dashboard (updated every batch by SM §4a):

Project         | PRs/week | Tokens/session | Health  | Stall risk
----------------|----------|----------------|---------|------------
kro-ui          | 14       | 42K            | GREEN   | Low
kardinal        | 8        | 31K            | GREEN   | Low
otherness       | 22       | 28K            | AMBER   | Medium (queue thin)

Comparative signal:
  kro-ui velocity: +12% vs last 7 days
  kardinal:        -3% vs last 7 days (within normal range)
  otherness:       -31% vs last 7 days (⚠ queue emptying)

Top cost contributors this week:
  1. kro-ui: $4.20 (vision scan step: 60% of total)
  2. kardinal: $2.80
  3. otherness: $1.90
```

**Implementation**: SM §4a writes the fleet snapshot to a well-known location
(the `_state` branch of the otherness repo itself). A GitHub Actions workflow
on the otherness repo reads this snapshot and posts it to the configured
fleet report issue or Slack channel.

---

## Backend selection guide

| Use case | Recommended backend | Why |
|---|---|---|
| Already on AWS, want minimal setup | X-Ray (traces) + AMP (metrics) + AMG | Extends existing OIDC role, one billing relationship |
| Want best trace debugging UX | Honeycomb | BubbleUp, query builder, no schema needed |
| Want best dashboards + full stack | Grafana Cloud | Tempo + Mimir + Loki in one platform |
| On-premises / air-gapped | Grafana stack self-hosted OR Jaeger + Prometheus | Full control, no SaaS dependency |
| SOC2 / compliance focus | Splunk + AWS CloudTrail | Immutable, auditable, long retention |
| Startup / small team | Grafana Cloud free tier | Best free tier, no infrastructure |
| Enterprise, Datadog already | Datadog | OTLP native, APM, dashboards, alerts |

---

## Compliance considerations

**Data residency**: OTEL traces contain resource attributes that may include repo names,
project names, and session IDs. For EU-based teams under GDPR: ensure your OTLP backend
is EU-hosted or that your DPA covers the data processor. AWS X-Ray in `eu-west-1`,
Grafana Cloud EU region, or self-hosted Grafana are the recommended options.

**Data retention**: Standard OTLP trace retention (7–30 days) is typically sufficient
for operational use. Compliance audit logs (Layer 2) require longer retention — typically
1–3 years depending on regulation. Separate the operational telemetry backend from the
compliance audit log backend.

**What is NOT in traces**: LLM prompt content, file content, API response bodies, secrets.
The AI SDK telemetry standard explicitly excludes prompt/completion content to prevent
accidental PII exposure in traces. This is not configurable by the agent.

---

## Present (✅)

- ✅ Design doc written with four-layer model (2026-04-21)
- ✅ AWS backend recommendation updated to include AMP + AMG (2026-04-21)
- ✅ Prometheus clarification: accepts OTLP metrics, not traces (2026-04-21)
- ✅ 44.1 — `otherness-config-template.yaml`: `observability.otlp` section added (backend, enabled, service_name, endpoint_secret, headers_secret) (PR #901, 2026-04-22)

## Future (🔲)

**Layer 1 — Session telemetry (OTLP)**
- 🔲 44.2 — `otherness-scheduled.yml` Step 3: read OTLP config; if enabled + secrets present: inject `experimental.openTelemetry: true` into opencode config, set `OPENCODE_OTEL_ENABLED=true`
- 🔲 44.3 — `otherness-scheduled.yml` Steps A and B: when `OPENCODE_OTEL_ENABLED=true`, inject OTEL env vars with resource attributes (project, session, batch, step)
- 🔲 44.4 — AWS X-Ray backend: add ADOT sidecar container step to workflow when `backend: aws-xray` is configured
- 🔲 44.5 — `docs/observability.md`: user-facing guide with setup instructions per backend, example Grafana dashboard JSON, example queries for "most expensive sessions" and "slowest tool calls"

**Layer 2 — Security audit log**
- 🔲 44.6 — SM §4a: after every significant action (git push, PR merge, branch protection clear), write a structured JSON audit event to the configured sink. Sink options: S3 bucket, CloudWatch Logs, stdout (for GitHub Actions log capture).
- 🔲 44.7 — `otherness-config-template.yaml`: add `observability.audit_log` section (enabled, sink: s3|cloudwatch|stdout, bucket/log_group)
- 🔲 44.8 — `onboarding-new-project.md`: add §Security audit log section explaining what is logged and how to configure the sink for compliance requirements.

**Layer 3 — Cost governance**
- 🔲 44.9 — SM §4b: compute per-session token cost from AI SDK span data (input tokens × price + output tokens × price). Accumulate to `state.json` as `tokens_total` and `cost_usd_estimate`.
- 🔲 44.10 — SM §4a: read project budget from `observability.cost.daily_budget_usd` in config. If today's estimated cost exceeds 80%: post warning. If 100%: pause loop (set `COST_LIMIT_REACHED=true` in state, COORD skips claiming until next day).
- 🔲 44.11 — SM §4f: monthly cost report — at calendar month boundary, post a summary (tokens, estimated cost, session count, anomaly count) to the report issue.
- 🔲 44.12 — SM §4b: anomaly detection — if session token count >3× 30-day rolling average: open `[COST ANOMALY]` issue, pause loop pending human review.

**Layer 4 — Fleet intelligence**
- 🔲 44.13 — SM §4a: write fleet snapshot (PRs/week, tokens/session, health, stall risk) to `_state` branch of otherness repo. Format: JSON keyed by project.
- 🔲 44.14 — `otherness-scheduled.yml`: add fleet report step that reads the snapshot and posts to a configured Slack webhook or fleet report issue.
- 🔲 44.15 — PM §5: compute velocity trend (PRs/week vs previous 7 days) per project and include in SM §4f health comment.

---

## Zone 1 — Obligations

**O1 — Zero config = zero telemetry.** Default state: no OTLP export, no audit log, no cost tracking. Every layer requires explicit opt-in in `otherness-config.yaml`.

**O2 — No central aggregation. No otherness-operated backend.** Each customer's telemetry goes to their own infrastructure. No otherness-hosted dashboard, no otherness-seen traces. Any PR that adds a default endpoint is a security violation.

**O3 — Audit log entries are never mutable.** Once written to the audit sink, an entry is never updated or deleted by the agent. Append-only. Sinks must be configured with write-only access (e.g. S3 bucket with `s3:PutObject` only, no `s3:DeleteObject`).

**O4 — Cost anomaly detection pauses, not stops.** A `COST_LIMIT_REACHED` state pauses item claiming but does not terminate the session. SM and PM phases still run. The agent can still close stale issues and post health signals. Only new feature work is paused.

**O5 — OTLP failure is non-blocking.** A failed export never stops the loop. Log as warning, continue.

**O6 — Traces never contain prompt content or file content.** The AI SDK telemetry standard excludes these. No agent phase adds them to spans. This is a data protection guarantee, not a preference.

**O7 — Resource attributes identify the session, not individuals.** Tags include project (repo slug), session ID, batch number, step. No usernames, no email addresses, no personal identifiers.

---

## Zone 2 — Implementer's judgment

- Cost estimates: use a price table in `otherness-config-template.yaml` as defaults. The exact Bedrock prices per model/region change frequently — the agent reads this table, not hardcoded values.
- Anomaly threshold (3×): this is conservative. Projects early in their lifecycle have high variance. The 30-day rolling average provides natural dampening. Projects less than 30 days old use a 7-day window instead.
- ADOT sidecar for X-Ray: the ADOT collector image (`amazon/aws-otel-collector:latest`) must also be SHA-pinned per design doc 27 §M1.
- The fleet snapshot format must be stable across otherness versions — use a versioned JSON schema (`fleet_snapshot_version: 1`).

---

## Zone 3 — Scoped out

- Real-time streaming telemetry (OTLP streaming, not batch export)
- Prompt content logging even with explicit customer opt-in (privacy risk too high)
- Otherness-operated SaaS dashboards
- Per-file change tracking beyond path (no diffs in audit log)
- Billing integration (chargebacks are reports, not automated transfers)
- Auto-remediation based on cost anomaly (human review always required)
