#!/usr/bin/env bash
# setup-github-bedrock-key.sh
#
# Sets up (or verifies) the GitHub Actions OIDC integration for Bedrock access.
# No long-lived credentials are created. GitHub Actions gets short-lived tokens
# per-run by assuming the IAM role via OIDC — compliant with Amazon security policy.
#
# What this script manages:
#   - IAM OIDC provider: token.actions.githubusercontent.com
#   - IAM role: github-bedrock-key  (scoped to GITHUB_REPO)
#   - Inline policy: BedrockInvoke
#   - GitHub secret: AWS_ROLE_ARN (optional, via --update-secrets)
#
# Usage:
#   ./scripts/setup-github-bedrock-key.sh
#   ./scripts/setup-github-bedrock-key.sh --update-secrets
#   AWS_PROFILE=default ./scripts/setup-github-bedrock-key.sh --update-secrets

set -euo pipefail

AWS_PROFILE="${AWS_PROFILE:-default}"
ROLE_NAME="github-bedrock-key"
GITHUB_REPO="pnz1990/otherness"
ACCOUNT_ID="569190534191"
OIDC_PROVIDER_URL="https://token.actions.githubusercontent.com"
OIDC_PROVIDER_ARN="arn:aws:iam::${ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com"
ROLE_ARN="arn:aws:iam::${ACCOUNT_ID}:role/${ROLE_NAME}"
UPDATE_SECRETS=false

while [[ $# -gt 0 ]]; do
  case $1 in
    --update-secrets) UPDATE_SECRETS=true; shift ;;
    *) echo "Unknown argument: $1" >&2; exit 1 ;;
  esac
done

echo "==> AWS profile:  $AWS_PROFILE"
echo "==> Account:      $ACCOUNT_ID"
echo "==> Role:         $ROLE_ARN"
echo "==> GitHub repo:  $GITHUB_REPO"
echo ""

# ── 1. OIDC provider ────────────────────────────────────────────────────────
echo "── Step 1: OIDC identity provider"
EXISTING=$(AWS_PROFILE="$AWS_PROFILE" aws iam list-open-id-connect-providers \
  --query "OpenIDConnectProviderList[?Arn=='${OIDC_PROVIDER_ARN}'].Arn" \
  --output text 2>/dev/null || true)

if [[ -n "$EXISTING" ]]; then
  echo "   OK  already exists: $OIDC_PROVIDER_ARN"
else
  echo "   Creating OIDC provider..."
  AWS_PROFILE="$AWS_PROFILE" aws iam create-open-id-connect-provider \
    --url "$OIDC_PROVIDER_URL" \
    --client-id-list sts.amazonaws.com \
    --thumbprint-list 6938fd4d98bab03faadb97b34396831e3780aea1 \
    --output text
  echo "   Created: $OIDC_PROVIDER_ARN"
fi

# ── 2. IAM role ──────────────────────────────────────────────────────────────
echo "── Step 2: IAM role $ROLE_NAME"
TRUST_POLICY=$(python3 -c "
import json
print(json.dumps({
  'Version': '2012-10-17',
  'Statement': [{
    'Sid': 'GitHubOIDC',
    'Effect': 'Allow',
    'Principal': {'Federated': '${OIDC_PROVIDER_ARN}'},
    'Action': 'sts:AssumeRoleWithWebIdentity',
    'Condition': {
      'StringEquals': {
        'token.actions.githubusercontent.com:aud': 'sts.amazonaws.com'
      },
      'StringLike': {
        'token.actions.githubusercontent.com:sub': 'repo:${GITHUB_REPO}:*'
      }
    }
  }]
}))
")

ROLE_EXISTS=$(AWS_PROFILE="$AWS_PROFILE" aws iam get-role \
  --role-name "$ROLE_NAME" \
  --query 'Role.Arn' --output text 2>/dev/null || true)

if [[ -n "$ROLE_EXISTS" ]]; then
  echo "   OK  role already exists, updating trust policy..."
  AWS_PROFILE="$AWS_PROFILE" aws iam update-assume-role-policy \
    --role-name "$ROLE_NAME" \
    --policy-document "$TRUST_POLICY"
else
  echo "   Creating role..."
  AWS_PROFILE="$AWS_PROFILE" aws iam create-role \
    --role-name "$ROLE_NAME" \
    --description "GitHub Actions OIDC role for ${GITHUB_REPO} - Bedrock invoke" \
    --assume-role-policy-document "$TRUST_POLICY" \
    --tags Key=Purpose,Value="GitHub Actions Bedrock/OpenCode" Key=CreatedBy,Value=rrroizma \
    --output text
fi

# ── 3. Bedrock policy ────────────────────────────────────────────────────────
echo "── Step 3: Bedrock inline policy"
AWS_PROFILE="$AWS_PROFILE" aws iam put-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-name BedrockInvoke \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [{
      "Sid": "BedrockInvoke",
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel",
        "bedrock:InvokeModelWithResponseStream",
        "bedrock:ListFoundationModels",
        "bedrock:ListInferenceProfiles",
        "bedrock:GetFoundationModel",
        "bedrock:GetInferenceProfile"
      ],
      "Resource": "*"
    }]
  }'
echo "   OK  BedrockInvoke policy applied"

# ── 4. GitHub secret ─────────────────────────────────────────────────────────
echo "── Step 4: GitHub secret"
if [[ "$UPDATE_SECRETS" == true ]]; then
  if ! command -v gh &>/dev/null; then
    echo "   ERROR: gh CLI not found." >&2; exit 1
  fi
  echo "$ROLE_ARN"    | gh secret set AWS_ROLE_ARN      --repo "$GITHUB_REPO"
  echo "$ACCOUNT_ID"  | gh secret set AWS_ACCOUNT_ID    --repo "$GITHUB_REPO"
  echo "us-east-1"    | gh secret set AWS_DEFAULT_REGION --repo "$GITHUB_REPO"
  echo "   OK  secrets pushed to $GITHUB_REPO"
else
  echo "   Skipped. Re-run with --update-secrets to push to GitHub, or add manually:"
  echo ""
  echo "     Secret name       Value"
  echo "     AWS_ROLE_ARN      $ROLE_ARN"
  echo "     AWS_ACCOUNT_ID    $ACCOUNT_ID"
  echo "     AWS_DEFAULT_REGION  us-east-1"
fi

# ── 5. Summary ───────────────────────────────────────────────────────────────
cat <<EOF

============================================================
  SETUP COMPLETE
  Role ARN: $ROLE_ARN
  Scoped to: $GITHUB_REPO (all branches/tags)
============================================================

Add this to your GitHub Actions workflow:

    - name: Configure AWS credentials
      uses: aws-actions/configure-aws-credentials@v4
      with:
        role-to-assume: \${{ secrets.AWS_ROLE_ARN }}
        role-session-name: otherness-bedrock
        aws-region: us-east-1

    - name: Call Bedrock / run OpenCode
      env:
        AWS_DEFAULT_REGION: us-east-1
      run: |
        # opencode or aws bedrock invoke-model ...

No secrets to rotate. Credentials are ephemeral per-run.
============================================================
EOF
