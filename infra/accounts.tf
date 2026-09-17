# Fase 2 — Cuentas por proyecto (una cuenta AWS por proyecto/entorno).
#
# Empezamos con dian-bot como PILOTO (el proyecto más fácil: casi stateless, ya
# es IaC). Validado el patrón end-to-end, se replican las demás.
#
# COSTO: crear una cuenta miembro en AWS Organizations es GRATIS. Cada cuenta
# nueva trae su propio free tier.
#
# IMPORTANTE (irreversibilidad): crear la cuenta es inmediato, pero eliminarla
# no es trivial — Terraform por defecto NO la cierra al hacer destroy (la saca
# de la org); cerrarla de verdad implica el proceso de AWS con espera de 90
# días. Por eso no ponemos close_on_deletion.

resource "aws_organizations_account" "dian_bot" {
  name      = "dian-bot"
  email     = var.account_emails["dian-bot"]
  parent_id = aws_organizations_organizational_unit.workloads.id

  # Rol que Organizations preconfigura en la cuenta nueva; confía en la
  # management account para asumir admin (acceso vía SSO/CLI).
  role_name = "OrganizationAccountAccessRole"

  # No cerrar la cuenta si se remueve del state (evita el proceso de 90 días por
  # accidente). El cierre, si algún día se necesita, se hace conscientemente.
  close_on_deletion = false

  lifecycle {
    # El email y el nombre no deben cambiarse por accidente (forzarían recreación
    # o son inmutables en AWS).
    ignore_changes = [role_name]
  }
}

output "dian_bot_account_id" {
  description = "ID de la cuenta AWS dian-bot (Fase 2 piloto)."
  value       = aws_organizations_account.dian_bot.id
}

# --- Resto de cuentas de la OU Workloads (Fase 2) ---
# dian-bot se mantiene como recurso individual arriba (ya creado; pasarlo a
# for_each forzaría recreación, y una cuenta AWS no debe recrearse). Las demás
# se crean con for_each sobre el resto del map de emails.
locals {
  workload_accounts = {
    for name, email in var.account_emails : name => email
    if name != "dian-bot"
  }
}

resource "aws_organizations_account" "workload" {
  for_each = local.workload_accounts

  name      = each.key
  email     = each.value
  parent_id = aws_organizations_organizational_unit.workloads.id
  role_name = "OrganizationAccountAccessRole"

  close_on_deletion = false

  lifecycle {
    ignore_changes = [role_name]
  }
}

output "workload_account_ids" {
  description = "IDs de las cuentas de la OU Workloads (además de dian-bot)."
  value       = { for name, acct in aws_organizations_account.workload : name => acct.id }
}
