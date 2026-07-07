#!/usr/bin/env bash
set -euo pipefail

echo "==> Running terraform fmt on infra/"
terraform fmt -recursive infra/

echo "==> Done. All files are formatted."
