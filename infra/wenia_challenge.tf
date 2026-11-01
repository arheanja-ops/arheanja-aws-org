# Reto tecnico Wenia (Platform Engineer) — cuenta aislada y desechable.
#
# OU propia DEBAJO DE ROOT (no de Workloads) a proposito: Workloads hereda
# deny-expensive (bloquea ec2:CreateNatGateway) y require-tags, y las sesiones
# del reto necesitan EKS con NAT unas horas. Aqui solo se aplican region-lock y
# protect-org. Las sesiones de pago se limitan con el presupuesto de abajo y con
# terraform destroy al terminar cada sesion.
#
# COSTO: OU, cuenta, SCP y asignacion SSO son gratis. El presupuesto tambien.

resource "aws_organizations_organizational_unit" "wenia_challenge" {
  name      = "Wenia-challenge"
  parent_id = local.root_id
}

resource "aws_organizations_account" "wenia_reto" {
  name      = "wenia-reto"
  email     = var.account_emails["wenia-reto"]
  parent_id = aws_organizations_organizational_unit.wenia_challenge.id

  role_name         = "OrganizationAccountAccessRole"
  close_on_deletion = false

  lifecycle {
    prevent_destroy = true
    ignore_changes  = [role_name, iam_user_access_to_billing]
  }
}

# --- Guardrails: reutiliza las SCPs existentes (scps.tf) ---
resource "aws_organizations_policy_attachment" "wenia_challenge_region_lock" {
  policy_id = aws_organizations_policy.region_lock.id
  target_id = aws_organizations_organizational_unit.wenia_challenge.id
}

resource "aws_organizations_policy_attachment" "wenia_challenge_protect_org" {
  policy_id = aws_organizations_policy.protect_org.id
  target_id = aws_organizations_organizational_unit.wenia_challenge.id
}

# --- Acceso: jaime.admin -> AdministratorAccess (reutiliza permission set y usuario) ---
resource "aws_ssoadmin_account_assignment" "wenia_reto_admin" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn

  principal_id   = data.aws_identitystore_user.owner.user_id
  principal_type = "USER"

  target_id   = aws_organizations_account.wenia_reto.id
  target_type = "AWS_ACCOUNT"
}

# --- Presupuesto: alerta al 80% real y al 100% previsto de la cuenta del reto ---
variable "wenia_budget_usd" {
  description = "Presupuesto mensual (USD) de la cuenta wenia-reto."
  type        = number
  default     = 5
}

variable "wenia_budget_emails" {
  description = "Correos que reciben las alertas del presupuesto del reto."
  type        = list(string)
  default     = ["arheanja@gmail.com"]
}

resource "aws_budgets_budget" "wenia_reto" {
  name         = "wenia-reto-monthly"
  budget_type  = "COST"
  limit_amount = tostring(var.wenia_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  cost_filter {
    name   = "LinkedAccount"
    values = [aws_organizations_account.wenia_reto.id]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = var.wenia_budget_emails
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_email_addresses = var.wenia_budget_emails
  }
}

output "ou_wenia_challenge_id" {
  value = aws_organizations_organizational_unit.wenia_challenge.id
}

output "wenia_reto_account_id" {
  description = "ID de la cuenta wenia-reto (reto tecnico Wenia)."
  value       = aws_organizations_account.wenia_reto.id
}
