terraform {
  required_version = ">= 1.5"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
  # No remote state — project owner applies this manually.
  # State is local (terraform.tfstate). Keep it out of git (see .gitignore).
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Owner      = "otherness"
      Purpose    = "observability"
      ManagedBy  = "otherness-agent"
    }
  }
}

# ── Data: existing OIDC role ───────────────────────────────────────────────────
# The role already exists with Bedrock permissions. We extend it — not replace it.
data "aws_iam_role" "oidc" {
  name = var.oidc_role_name
}

# ── Amazon Managed Prometheus (AMP) workspace ─────────────────────────────────
resource "aws_prometheus_workspace" "otherness" {
  alias = "otherness-observability"

  tags = {
    Component = "amp"
  }
}

# ── Amazon Managed Grafana (AMG) workspace ────────────────────────────────────
resource "aws_grafana_workspace" "otherness" {
  name                     = "otherness-observability"
  description              = "Otherness autonomous-team observability: session telemetry, token cost, fleet health."
  account_access_type      = "CURRENT_ACCOUNT"
  authentication_providers = ["SAML"]
  permission_type          = "SERVICE_MANAGED"
  role_arn                 = aws_iam_role.grafana_service.arn

  # GitHub OAuth is configured post-apply via SAML/SSO federation.
  # See README.md §GitHub OAuth setup for step-by-step instructions.

  data_sources = ["PROMETHEUS", "XRAY"]

  tags = {
    Component = "amg"
  }
}

# ── IAM role for AMG service ──────────────────────────────────────────────────
resource "aws_iam_role" "grafana_service" {
  name               = "otherness-grafana-service"
  assume_role_policy = data.aws_iam_policy_document.grafana_assume.json

  tags = {
    Component = "amg"
  }
}

data "aws_iam_policy_document" "grafana_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["grafana.amazonaws.com"]
    }
  }
}

resource "aws_iam_role_policy" "grafana_data_sources" {
  name   = "otherness-grafana-data-sources"
  role   = aws_iam_role.grafana_service.id
  policy = data.aws_iam_policy_document.grafana_data_sources.json
}

data "aws_iam_policy_document" "grafana_data_sources" {
  # AMP read access for Grafana
  statement {
    effect = "Allow"
    actions = [
      "aps:QueryMetrics",
      "aps:GetSeries",
      "aps:GetLabels",
      "aps:GetMetricMetadata",
      "aps:ListWorkspaces",
      "aps:DescribeWorkspace",
    ]
    resources = [aws_prometheus_workspace.otherness.arn]
  }
  # X-Ray read access for Grafana
  statement {
    effect = "Allow"
    actions = [
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
      "xray:GetSamplingStatisticSummaries",
      "xray:BatchGetTraces",
      "xray:GetServiceGraph",
      "xray:GetTraceGraph",
      "xray:GetTraceSummaries",
      "xray:GetGroups",
      "xray:GetGroup",
      "xray:ListTagsForResource",
    ]
    resources = ["*"]
  }
}

# ── IAM policy additions for existing OIDC role ───────────────────────────────
# Extends the Bedrock OIDC role with the minimum permissions needed to emit
# OTLP telemetry (X-Ray traces + AMP metrics remote write).
# Does NOT create a new role — attaches an inline policy to the existing one.
resource "aws_iam_role_policy" "otlp_emit" {
  name   = "otherness-otlp-emit"
  role   = data.aws_iam_role.oidc.id
  policy = data.aws_iam_policy_document.otlp_emit.json
}

data "aws_iam_policy_document" "otlp_emit" {
  # X-Ray: write traces
  statement {
    sid    = "XRayEmit"
    effect = "Allow"
    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
      "xray:GetSamplingRules",
      "xray:GetSamplingTargets",
    ]
    resources = ["*"]
  }
  # AMP: remote write metrics
  statement {
    sid    = "AMPRemoteWrite"
    effect = "Allow"
    actions = [
      "aps:RemoteWrite",
    ]
    resources = [aws_prometheus_workspace.otherness.arn]
  }
}
