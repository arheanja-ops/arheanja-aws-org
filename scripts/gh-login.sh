#!/usr/bin/env bash
# Autentica gh en el GH_CONFIG_DIR aislado de este repo.
# Uso: ./scripts/gh-login.sh
set -euo pipefail
if [ -z "${GH_CONFIG_DIR:-}" ]; then
  echo "⚠️  GH_CONFIG_DIR no seteado — ¿corriste fuera del repo o sin direnv?"
  exit 1
fi
echo "→ gh aislado (GH_CONFIG_DIR: $GH_CONFIG_DIR)"
if gh auth status >/dev/null 2>&1; then
  gh auth status
else
  echo "⏳ Sin sesión — autorizando (usa la cuenta arheanja-ops)…"
  gh auth login --hostname github.com --git-protocol https --web
fi
