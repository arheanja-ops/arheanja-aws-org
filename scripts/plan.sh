#!/usr/bin/env bash
# Terraform plan de la organización. Uso: ./scripts/plan.sh
set -euo pipefail
cd "$(dirname "$0")/../infra"
terraform init -input=false >/dev/null
terraform fmt -recursive >/dev/null
terraform validate
terraform plan -input=false "$@"
