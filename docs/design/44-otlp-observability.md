# 44: OTLP Observability — Session Telemetry for Project Owners

> Status: Active | Created: 2026-04-21
> Applies to: all projects managed by otherness
> OpenCode versions: experimental.openTelemetry available since v1.4.0; OTEL_RESOURCE_ATTRIBUTES since v1.14.17

---

## Traces vs metrics — what OTLP gives you

**OTLP carries two distinct signal types:**

| Signal | What it is | What you see |
|---|---|---|
| **Traces** | Per-session span tree | LLM calls, tool invocations, latency breakdown for a specific batch |
| **Metrics** | Aggregated time-series | Token/hour over 7 days, p99 session latency, error rate |

The Vercel AI SDK (which OpenCode uses) emits **both** via OTLP. You can send each to
a different backend.

**Prometheus**: Since v2.47, Prometheus has an OTLP write endpoint
(`/api/v1/otlp/v1/metrics`) and accepts OTLP **metrics** — not traces. If you already
run Prometheus (or Amazon Managed Prometheus), you can get token counts and latency
histograms as time-series there. Combine with Grafana for dashboards.

**For traces specifically**: Prometheus is not the right tool — it doesn't store span
trees. Use AWS X-Ray, Grafana Tempo, Jaeger, or Honeycomb for the per-session detail.

**Recommended full stack on AWS:**
```
OpenCode session
  ├── OTLP traces  ──→ AWS X-Ray        (per-session detail, debugging)
  └── OTLP metrics ──→ Amazon Managed   (trends, token/hour, p99 over time)
                        Prometheus
                        └── Amazon Managed Grafana (dashboards for both)
```

This uses only AWS-managed services, zero self-hosted infrastructure, and the existing
OIDC role (with two additional IAM permissions each for X-Ray and AMP).

---

## What this does

OpenCode supports exporting AI SDK telemetry spans to any OTLP backend. When enabled,
every session emits structured trace data: one span per LLM call (model, tokens,
latency), one span per tool invocation (tool name, duration), and resource tags
identifying which project, session, and batch produced the trace.

This gives project owners — the humans using otherness — visibility into where their
sessions spend time and tokens, without otherness having access to anyone's data. Each
customer's traces go to their own backend, configured in their own repository secrets.
Otherness never sees them.

**This is strictly opt-in.** No configuration = no telemetry = no data sent anywhere.
The default state is identical to today.

---

## What you can see

With OTLP enabled on a project, traces include:

| Span | What you learn |
|---|---|
| `ai.generateText` | LLM call: model, input tokens, output tokens, latency, finish reason |
| `ai.streamText` | Streaming LLM call: same as above, time-to-first-token included |
| `ai.toolCall` | Tool invocation: tool name, duration. Which tools are slow? |
| Session root span | Full session: total duration, steps count, batch number |

With `OTEL_RESOURCE_ATTRIBUTES` tags:
```
service.name=otherness
project=pnz1990/kro-ui
session=sess-abc123
batch=47
step=vision-scan OR step=run
```

**Questions you can answer from these traces:**
- How many tokens does a typical session consume? Which step (vision vs run) uses more?
- Which tool calls are slowest? (`gh api` rate-limit waits, large file reads, etc.)
- Do sessions with `session_item_limit=3` finish faster than `session_item_limit=5`?
- Which sessions timeout and at what point? (OIDC expiry correlates with total duration)
- Is the vision scan step (Step A) adding meaningful latency vs its value?

---

## What you cannot see

- The content of LLM prompts or responses (not included in standard AI SDK spans)
- File contents read or written (tool arguments are not in the span payload)
- GitHub API response bodies
- Any other project's traces (each project has its own backend secret)

---

## Architecture

```
GitHub Actions runner
  └── OpenCode session
        ├── Step A (Vision scan)
        │     └── AI SDK spans → OTLP exporter → YOUR backend
        └── Step B (Run)
              └── AI SDK spans → OTLP exporter → YOUR backend

Your OTLP backend (Grafana Cloud, Honeycomb, Jaeger, any OpenTelemetry-compatible backend)
  └── Traces with resource tags: project=pnz1990/kro-ui, batch=47, step=run
```

There is no central aggregation. otherness never sees your traces. Each project
is independently configured and independently observed.

---

## Configuration

### Step 1 — Choose an OTLP backend

Any OpenTelemetry-compatible backend works.

**AWS X-Ray (recommended if you're already on AWS)**

otherness already has an AWS OIDC role for Bedrock. Adding X-Ray is zero new
infrastructure — just two extra IAM permissions on the existing role:

```json
{
  "Effect": "Allow",
  "Action": ["xray:PutTraceSegments", "xray:PutTelemetryRecords"],
  "Resource": "*"
}
```

With those permissions, the AWS Distro for OpenTelemetry (ADOT) collector runs
as a sidecar in the same GitHub Actions job and forwards spans to X-Ray. No new
account, no new billing, 100K traces/month free.

OTLP endpoint: `http://localhost:4318` (ADOT collector localhost)
Auth: none needed — the OIDC role handles it via SigV4

**Other options:**

| Backend | Free tier | Notes |
|---|---|---|
| **Grafana Cloud** | 50GB traces/month | Best dashboards; Tempo backend for traces |
| **Honeycomb** | 20M events/month | Best ad-hoc query UX |
| **Jaeger** | Self-hosted | Run it anywhere; no cloud dependency |
| **Signoz** | Self-hosted / cloud | Open-source Datadog alternative |
| **Datadog** | Paid | Most complete; expensive at scale |

### Step 2 — Add secrets to your repository

**AWS X-Ray path** — add the two IAM permissions to your OIDC role (no secrets needed):
```json
{ "Action": ["xray:PutTraceSegments", "xray:PutTelemetryRecords"], "Resource": "*" }
```
Set endpoint to the ADOT collector localhost (added automatically by the install step
when X-Ray mode is detected):
```bash
gh secret set OTEL_EXPORTER_OTLP_ENDPOINT \
  --body "http://localhost:4318" \
  --repo your-org/your-project
```

**Other backends** — set endpoint and auth header for your provider:
```bash
gh secret set OTEL_EXPORTER_OTLP_ENDPOINT \
  --body "https://otlp-gateway-prod-us-east-0.grafana.net/otlp" \
  --repo your-org/your-project

# Auth header format depends on your backend:
# Grafana Cloud: "Authorization=Basic <base64(instanceID:apikey)>"
# Honeycomb:     "x-honeycomb-team=YOUR_API_KEY"
gh secret set OTEL_EXPORTER_OTLP_HEADERS \
  --body "Authorization=Basic YOUR_ENCODED_CREDENTIALS" \
  --repo your-org/your-project
```

### Step 3 — Enable in otherness-config.yaml

```yaml
# In your project's otherness-config.yaml
observability:
  otlp_enabled: true      # default: false — no telemetry without this
  # service_name is optional; defaults to "otherness"
  service_name: "otherness"
```

### Step 4 — The workflow configures itself

When `otlp_enabled: true` and the secrets are present, the scheduled workflow
automatically adds to both Step A and Step B:

```yaml
env:
  # OTLP export (standard OpenTelemetry env vars)
  OTEL_EXPORTER_OTLP_ENDPOINT: ${{ secrets.OTEL_EXPORTER_OTLP_ENDPOINT }}
  OTEL_EXPORTER_OTLP_HEADERS:  ${{ secrets.OTEL_EXPORTER_OTLP_HEADERS }}
  OTEL_RESOURCE_ATTRIBUTES: >-
    service.name=otherness,
    project=${{ github.repository }},
    batch=${{ env.SM_CYCLE }},
    step=vision-scan   # or: step=run
```

And the opencode config (`~/.opencode/config.json` or `opencode.json` in the project)
gets `experimental.openTelemetry: true` appended by the install step.

---

## Present (✅)

- ✅ Design doc created (this file) (2026-04-21)

## Future (🔲)

- 🔲 44.1 — `otherness-config-template.yaml`: add `observability.otlp_enabled` and `observability.service_name` fields with comments explaining what they do and linking to this design doc.
- 🔲 44.2 — `otherness-scheduled.yml` Step 3 (Install): read `otlp_enabled` from config. If true and `OTEL_EXPORTER_OTLP_ENDPOINT` secret is present: write `experimental.openTelemetry: true` to the opencode config file in the runner, and set `OPENCODE_OTEL_ENABLED=true` env var for steps A and B to read.
- 🔲 44.3 — `otherness-scheduled.yml` Steps A and B: when `OPENCODE_OTEL_ENABLED=true`, add `OTEL_EXPORTER_OTLP_ENDPOINT`, `OTEL_EXPORTER_OTLP_HEADERS`, and `OTEL_RESOURCE_ATTRIBUTES` to the step env. Resource attributes: `service.name`, `project`, and `step` (vision-scan vs run).
- 🔲 44.4 — `onboarding-new-project.md`: add §Observability section explaining the opt-in OTLP setup, what you can see, and the three supported backends with free tier links.
- 🔲 44.5 — `docs/observability.md`: user-facing guide. What traces look like, example dashboards for Grafana/Honeycomb, queries to answer "which sessions used the most tokens", "which tool calls are slowest". With screenshots if possible.

---

## Zone 1 — Obligations

**O1 — Zero config = zero telemetry = nothing sent.** The default state must be
identical to today. `otlp_enabled` defaults to `false`. No env var, no network call,
no data transmitted. If `OTEL_EXPORTER_OTLP_ENDPOINT` secret is absent, the workflow
skips all OTEL configuration regardless of `otlp_enabled`.

**O2 — No central aggregation.** Otherness never configures a default OTLP endpoint.
There is no otherness-operated backend. Each customer's traces go to their own backend.
Any change to this design doc that adds a default endpoint is a security violation.

**O3 — Secrets are not logged.** The `OTEL_EXPORTER_OTLP_HEADERS` secret contains
auth credentials. The workflow step that reads it must never echo it to stdout.
GitHub Actions masks secrets automatically but the workflow must not explicitly log them.

**O4 — OTLP failure is non-blocking.** If the OTLP export fails (network error, invalid
endpoint, auth failure), the session continues normally. A failed trace export is logged
as a warning, not an error. The agent loop must never stop because telemetry failed.

**O5 — Resource attributes include project and step, not user data.** The
`OTEL_RESOURCE_ATTRIBUTES` value contains only: `service.name`, `project` (repo slug),
`step` (vision-scan or run), and `batch` (SM cycle number). No file paths, no issue
numbers, no PR content, no usernames.

---

## Zone 2 — Implementer's judgment

- The opencode config for `experimental.openTelemetry: true` can be written to
  `~/.opencode/config.json` by the install step. This is a JSON file; use `jq` to
  merge rather than overwrite to avoid clobbering other settings.
- Batch number: the SM cycle counter is in `state.json`. Reading it in the install
  step requires `git show origin/_state:.otherness/state.json` — the same pattern
  used elsewhere. If unavailable, omit the `batch` attribute.
- `OTEL_RESOURCE_ATTRIBUTES` format: comma-separated `key=value` pairs, no spaces
  around `=`, URL-encode any values with commas.

---

## Zone 3 — Scoped out

- Metrics export (OTLP metrics endpoint — separate from traces)
- Log export to OTLP
- Sampling configuration (100% sampling by default; configurable by the customer
  in their own OTLP collector)
- Any otherness-operated observability backend or dashboard
- Tracing the otherness agent phases themselves (only AI SDK spans are in scope;
  the bash/python code in phases/*.md is not instrumented)
