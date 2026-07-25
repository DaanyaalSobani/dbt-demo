#!/usr/bin/env bash
# bootstrap.sh — install the AWS CLI v2 if needed and verify credentials.
# Idempotent: safe to run repeatedly.
set -euo pipefail
cd "$(dirname "$0")"

if [[ ! -f .env ]]; then
  echo "ERROR: .env not found." >&2
  echo "Copy the template and fill in your AWS credentials first:" >&2
  echo "  cp .env.example .env" >&2
  exit 1
fi

# Export everything sourced from .env so the AWS CLI (a child process) sees it.
set -a
source .env
set +a

install_aws_cli() {
  local os arch
  os="$(uname -s)"
  case "$os" in
    Darwin)
      echo "Installing AWS CLI v2 for macOS (works on Intel and Apple Silicon)..."
      curl -fsSL "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o /tmp/AWSCLIV2.pkg
      sudo installer -pkg /tmp/AWSCLIV2.pkg -target /
      rm -f /tmp/AWSCLIV2.pkg
      ;;
    Linux)
      # uname -m is x86_64 on Intel/AMD and aarch64 on ARM (e.g. Graviton,
      # Raspberry Pi) — AWS publishes a matching installer for each.
      arch="$(uname -m)"
      echo "Installing AWS CLI v2 for Linux ($arch)..."
      curl -fsSL "https://awscli.amazonaws.com/awscli-exe-linux-${arch}.zip" -o /tmp/awscliv2.zip
      (cd /tmp && unzip -qo awscliv2.zip && sudo ./aws/install --update)
      rm -rf /tmp/awscliv2.zip /tmp/aws
      ;;
    *)
      echo "ERROR: unsupported OS: $os (this script handles macOS and Linux)" >&2
      exit 1
      ;;
  esac
}

if command -v aws >/dev/null 2>&1 && aws --version 2>&1 | grep -q '^aws-cli/2'; then
  echo "AWS CLI v2 already installed: $(aws --version)"
else
  install_aws_cli
  echo "Installed: $(aws --version)"
fi

echo "Verifying AWS credentials (aws sts get-caller-identity)..."
if ! identity="$(aws sts get-caller-identity --output json 2>&1)"; then
  echo "ERROR: AWS credentials are missing or invalid." >&2
  echo "" >&2
  echo "  $identity" >&2
  echo "" >&2
  echo "Check AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY in .env." >&2
  echo "Keys are created in the AWS console under:" >&2
  echo "  IAM > Users > your user > Security credentials > Create access key > CLI" >&2
  exit 1
fi

echo "$identity"
echo ""
echo "Credentials OK. You are cleared to propose: ./deploy.sh"
