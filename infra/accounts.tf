# Fase 2 — Cuentas por unidad de aislamiento (decisión 2026-09-18).
#
# Estructura acordada (proyectos personales, pre-monetización → pocas cuentas):
#   - ai-platform-arheanja : IA / agentes / bots (DIAN-bot, job-hunt-bot,
#                            matchstack, etc.). Es la cuenta ex "dian-bot".
#   - taxops               : TaxOps-11 + investment-self (aislamiento
#                            compartido, aceptado conscientemente).
#   - management (786567028012): solo billing/org/SSO — se vacía al final vía
#                            migraciones de workloads.
#
# COSTO: crear cuentas miembro es GRATIS; cada una trae su propio free tier.
# IRREVERSIBILIDAD: crear es inmediato; cerrar implica el proceso de 90 días de
# AWS. Por eso close_on_deletion = false.

# --- Cuenta de IA / agentes / bots (ex dian-bot, ya existente) ---
# Renombrada de "dian-bot" a "ai-platform-arheanja". Cambiar el friendly name de
# una cuenta miembro es un update in-place (no recrea la cuenta).
#
# El recurso Terraform pasó de "dian_bot" a "ai_platform": el moved block mueve
# el estado sin destruir/recrear la cuenta.
moved {
  from = aws_organizations_account.dian_bot
  to   = aws_organizations_account.ai_platform
}

resource "aws_organizations_account" "ai_platform" {
  name      = "ai-platform-arheanja"
  email     = var.account_emails["ai-platform"]
  parent_id = aws_organizations_organizational_unit.workloads.id

  role_name         = "OrganizationAccountAccessRole"
  close_on_deletion = false

  lifecycle {
    ignore_changes = [role_name]
  }
}

# --- Cuenta TaxOps (TaxOps-11 + investment-self) ---
resource "aws_organizations_account" "taxops" {
  name      = "taxops"
  email     = var.account_emails["taxops"]
  parent_id = aws_organizations_organizational_unit.workloads.id

  role_name         = "OrganizationAccountAccessRole"
  close_on_deletion = false

  lifecycle {
    ignore_changes = [role_name]
  }
}

output "ai_platform_account_id" {
  description = "ID de la cuenta ai-platform-arheanja (IA/agentes/bots)."
  value       = aws_organizations_account.ai_platform.id
}

output "taxops_account_id" {
  description = "ID de la cuenta taxops (TaxOps + investment-self)."
  value       = aws_organizations_account.taxops.id
}
