output "amp_workspace_id" {
  description = "Amazon Managed Prometheus workspace ID."
  value       = aws_prometheus_workspace.otherness.id
}

output "amp_remote_write_endpoint" {
  description = "AMP remote write endpoint URL. Set this as the AMP_REMOTE_WRITE_ENDPOINT GitHub secret on each managed project."
  value       = "${aws_prometheus_workspace.otherness.prometheus_endpoint}api/v1/remote_write"
}

output "amp_workspace_arn" {
  description = "AMP workspace ARN (used in IAM policy)."
  value       = aws_prometheus_workspace.otherness.arn
}

output "amg_workspace_id" {
  description = "Amazon Managed Grafana workspace ID."
  value       = aws_grafana_workspace.otherness.id
}

output "amg_workspace_url" {
  description = "Amazon Managed Grafana workspace URL. Open in browser to access dashboards."
  value       = "https://${aws_grafana_workspace.otherness.endpoint}"
}

output "grafana_service_role_arn" {
  description = "ARN of the IAM role created for the Grafana service."
  value       = aws_iam_role.grafana_service.arn
}
