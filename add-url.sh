#!/usr/bin/env bash
# add-url.sh — expose the function via a public Function URL and print it.
# Idempotent: safe to run repeatedly.
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
  echo "Function URL config already exists"
else
  echo "Creating Function URL (auth type NONE — public)"
  aws lambda create-function-url-config \
    --function-name "$FUNCTION_NAME" \
    --auth-type NONE >/dev/null
fi

# Creating the URL config is NOT enough: without a resource-based policy
# granting lambda:InvokeFunctionUrl to the public, the URL returns
# 403 Forbidden. add-permission fails if the statement id already exists,
# so probe the existing policy first to stay idempotent.
STATEMENT_ID="AllowPublicFunctionUrlInvoke"
if aws lambda get-policy --function-name "$FUNCTION_NAME" \
     --query Policy --output text 2>/dev/null | grep -q "$STATEMENT_ID"; then
  echo "Public invoke permission already in place"
else
  echo "Granting public lambda:InvokeFunctionUrl permission"
  aws lambda add-permission \
    --function-name "$FUNCTION_NAME" \
    --statement-id "$STATEMENT_ID" \
    --action lambda:InvokeFunctionUrl \
    --principal '*' \
    --function-url-auth-type NONE >/dev/null
fi

URL="$(aws lambda get-function-url-config \
  --function-name "$FUNCTION_NAME" \
  --query FunctionUrl --output text)"

echo ""
echo "The proposal is live:"
echo ""
echo "  curl $URL"
echo ""
echo "(For science, also try: curl \"${URL}?answer=no\")"
