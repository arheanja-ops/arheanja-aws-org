# Fase 2 — Asignaciones de acceso SSO (quién entra a qué cuenta con qué rol).
#
# Sin una asignación, una cuenta nueva no es accesible por el portal SSO. Aquí
# damos al owner (jaime.admin) acceso AdministratorAccess a las cuentas de la
# OU Workloads.
# COSTO: $0 (IAM Identity Center no cobra por asignaciones).

# Usuario del Identity Store (se resuelve por username, no se hardcodea el ID).
data "aws_identitystore_user" "owner" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.this.identity_store_ids)[0]

  alternate_identifier {
    unique_attribute {
      attribute_path  = "UserName"
      attribute_value = "jaime.admin"
    }
  }
}

# jaime.admin -> AdministratorAccess en la cuenta ai-platform-arheanja.
# (Recurso renombrado desde dian_bot_admin; el moved block mueve el estado.)
moved {
  from = aws_ssoadmin_account_assignment.dian_bot_admin
  to   = aws_ssoadmin_account_assignment.ai_platform_admin
}

resource "aws_ssoadmin_account_assignment" "ai_platform_admin" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn

  principal_id   = data.aws_identitystore_user.owner.user_id
  principal_type = "USER"

  target_id   = aws_organizations_account.ai_platform.id
  target_type = "AWS_ACCOUNT"
}

# jaime.admin -> AdministratorAccess en la cuenta taxops.
resource "aws_ssoadmin_account_assignment" "taxops_admin" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn

  principal_id   = data.aws_identitystore_user.owner.user_id
  principal_type = "USER"

  target_id   = aws_organizations_account.taxops.id
  target_type = "AWS_ACCOUNT"
}
