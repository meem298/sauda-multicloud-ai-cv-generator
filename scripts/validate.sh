#!/usr/bin/env bash
# Syntax-only validation — does NOT call cloud APIs or download providers.
# Run this after terraform fmt to catch HCL errors before committing.
set -euo pipefail

ENVS=("infra/environments/dev" "infra/environments/prod" "infra/global/state-backend")

for env in "${ENVS[@]}"; do
  echo "==> Checking fmt: $env"
  terraform -chdir="$env" fmt -check -recursive
done

echo ""
echo "==> fmt checks passed. Run 'terraform init' + 'terraform validate' locally"
echo "    to do full validation (requires credentials)."
