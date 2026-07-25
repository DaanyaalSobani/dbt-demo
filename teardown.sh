#!/usr/bin/env bash
# teardown.sh — remove everything deploy.sh and add-url.sh created.
# Idempotent: each resource is probed first, so partial teardowns can be rerun.
set -euo pipefail
cd "$(dirname "$0")"

if [[ ! -f .env ]]; then
  echo "ERROR: .env not found. Run: cp .env.example .env  (then fill it in)" >&2
  exit 1
fi
set -a
source .env
set +a

if aws lambda get-function-url-config --function-name "$FUNCTION_NAME" >/dev/null 2>&1; then
  echo "Deleting Function URL config"
  aws lambda delete-function-url-config --function-name "$FUNCTION_NAME"
fi

if aws lambda get-function --function-name "$FUNCTION_NAME" >/dev/null 2>&1; then
  echo "Deleting function $FUNCTION_NAME"
  aws lambda delete-function --function-name "$FUNCTION_NAME"
fi

if aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
  echo "Detaching policies from role $ROLE_NAME"
  for policy_arn in $(aws iam list-attached-role-policies \
      --role-name "$ROLE_NAME" \
      --query 'AttachedPolicies[].PolicyArn' --output text); do
    aws iam detach-role-policy --role-name "$ROLE_NAME" --policy-arn "$policy_arn"
  done
  echo "Deleting role $ROLE_NAME"
  aws iam delete-role --role-name "$ROLE_NAME"
fi

rm -f function.zip

echo ""
echo "Torn down. (The engagement itself is non-revocable — see license.)"
