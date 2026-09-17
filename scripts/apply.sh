#!/usr/bin/env bash
# Terraform apply de la organización. Requiere confirmación interactiva salvo
# que pases -auto-approve. Uso: ./scripts/apply.sh
set -euo pipefail
cd "$(dirname "$0")/../infra"
terraform init -input=false >/dev/null
echo "⚠️  Vas a aplicar cambios en la ORGANIZACIÓN AWS ($AWS_PROFILE)."
terraform apply -input=false "$@"
