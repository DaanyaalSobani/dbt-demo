#!/usr/bin/env bash
# deploy.sh — package handler.py and create (or update) the Lambda function.
# Idempotent: existence is probed before every create; reruns fall back to update.
set -euo pipefail
cd "$(dirname "$0")"

if [[ ! -f .env ]]; then
  echo "ERROR: .env not found. Run: cp .env.example .env  (then fill it in)" >&2
  exit 1
fi
set -a
source .env
set +a

ZIP_FILE="function.zip"

echo "Packaging handler.py -> $ZIP_FILE"
rm -f "$ZIP_FILE"
if command -v zip >/dev/null 2>&1; then
  zip -j -q "$ZIP_FILE" handler.py
else
  python3 -m zipfile -c "$ZIP_FILE" handler.py
fi

# --- IAM execution role: create if missing, otherwise reuse -----------------
if aws iam get-role --role-name "$ROLE_NAME" >/dev/null 2>&1; then
  echo "IAM role $ROLE_NAME already exists — reusing"
else
  echo "Creating IAM role $ROLE_NAME"
  aws iam create-role \
    --role-name "$ROLE_NAME" \
    --assume-role-policy-document file://trust-policy.json >/dev/null

  # IAM is eventually consistent: if we call create-function immediately after
  # creating the role, Lambda fails with "The role defined for the function
  # cannot be assumed by Lambda". Wait for the role to propagate.
  echo "Waiting 10s for the IAM role to propagate..."
  sleep 10
fi

# attach-role-policy is naturally idempotent — re-attaching is a no-op.
aws iam attach-role-policy \
  --role-name "$ROLE_NAME" \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

ROLE_ARN="$(aws iam get-role --role-name "$ROLE_NAME" --query Role.Arn --output text)"

# --- Lambda function: create if missing, otherwise update code --------------
if aws lambda get-function --function-name "$FUNCTION_NAME" >/dev/null 2>&1; then
  echo "Function $FUNCTION_NAME already exists — updating code"
  aws lambda update-function-code \
    --function-name "$FUNCTION_NAME" \
    --zip-file "fileb://$ZIP_FILE" >/dev/null
else
  echo "Creating function $FUNCTION_NAME"
  aws lambda create-function \
    --function-name "$FUNCTION_NAME" \
    --runtime "$RUNTIME" \
    --handler "$HANDLER" \
    --role "$ROLE_ARN" \
    --zip-file "fileb://$ZIP_FILE" \
    --description "An over-engineered marriage proposal. Returns yes." >/dev/null
fi

echo "Waiting for the function to be ready..."
aws lambda wait function-active-v2 --function-name "$FUNCTION_NAME"
aws lambda wait function-updated-v2 --function-name "$FUNCTION_NAME"

echo ""
echo "Deployed $FUNCTION_NAME ($RUNTIME). Next: ./add-url.sh"
