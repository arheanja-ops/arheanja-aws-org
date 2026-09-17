#!/usr/bin/env bash
# Verifica/renueva la sesión SSO del profile de la management account.
# Uso: ./scripts/aws-login.sh
set -euo pipefail
PROFILE="${AWS_PROFILE:-taxops-admin}"
if aws sts get-caller-identity --profile "$PROFILE" >/dev/null 2>&1; then
  echo "✅ Sesión AWS activa ($PROFILE):"
  aws sts get-caller-identity --profile "$PROFILE" --output table
else
  echo "⏳ Sesión expirada — abriendo navegador…"
  aws sso login --profile "$PROFILE"
fi
