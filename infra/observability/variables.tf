variable "aws_region" {
  description = "AWS region to deploy observability resources into."
  type        = string
  default     = "us-east-1"
}

variable "oidc_role_name" {
  description = "Name of the existing OIDC IAM role used by GitHub Actions (Bedrock role). This role will be extended with X-Ray and AMP emit permissions."
  type        = string
  # No default — must be supplied. Typically matches AWS_ROLE_ARN in GitHub Secrets.
  # Extract with: aws sts get-caller-identity --query 'Arn' | sed 's|.*role/||;s|/.*||'
}
