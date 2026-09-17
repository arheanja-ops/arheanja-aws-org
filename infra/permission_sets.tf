# Fase 1 (resto) — IAM Identity Center (SSO) permission sets como código.
#
# Instancia real: ssoins-722353cec8cc0313 (identity store d-90667809b5).
# El permission set AdministratorAccess YA EXISTE (ps-72236cd8d2569a6b) y se
# adopta al state con un import block para no recrearlo.
# COSTO: SSO y permission sets son gratis. El tagging lo da default_tags.

data "aws_ssoadmin_instances" "this" {}

locals {
  sso_instance_arn = tolist(data.aws_ssoadmin_instances.this.arns)[0]
}

# --- AdministratorAccess (existente, se adopta) ---
# id de import de un permission set: "permissionSetArn,instanceArn".
import {
  to = aws_ssoadmin_permission_set.admin
  id = "arn:aws:sso:::permissionSet/ssoins-722353cec8cc0313/ps-72236cd8d2569a6b,arn:aws:sso:::instance/ssoins-722353cec8cc0313"
}

resource "aws_ssoadmin_permission_set" "admin" {
  name             = "AdministratorAccess"
  description      = "Acceso administrativo completo. Solo el owner, en cuentas propias."
  instance_arn     = local.sso_instance_arn
  session_duration = "PT8H"
}

resource "aws_ssoadmin_managed_policy_attachment" "admin" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# --- ReadOnly (nuevo) — auditoría ---
resource "aws_ssoadmin_permission_set" "readonly" {
  name             = "ReadOnly"
  description      = "Solo lectura para auditoría en cualquier cuenta."
  instance_arn     = local.sso_instance_arn
  session_duration = "PT4H"
}

resource "aws_ssoadmin_managed_policy_attachment" "readonly" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.readonly.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/ReadOnlyAccess"
}

# --- Billing (nuevo) — gestión de costos, pensado para la management account ---
resource "aws_ssoadmin_permission_set" "billing" {
  name             = "Billing"
  description      = "Acceso a facturación y costos."
  instance_arn     = local.sso_instance_arn
  session_duration = "PT4H"
}

resource "aws_ssoadmin_managed_policy_attachment" "billing" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.billing.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/job-function/Billing"
}

output "permission_set_admin_arn" {
  value = aws_ssoadmin_permission_set.admin.arn
}

output "permission_set_readonly_arn" {
  value = aws_ssoadmin_permission_set.readonly.arn
}

output "permission_set_billing_arn" {
  value = aws_ssoadmin_permission_set.billing.arn
}
