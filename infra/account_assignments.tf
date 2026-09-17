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

# jaime.admin -> AdministratorAccess en la cuenta dian-bot.
resource "aws_ssoadmin_account_assignment" "dian_bot_admin" {
  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn

  principal_id   = data.aws_identitystore_user.owner.user_id
  principal_type = "USER"

  target_id   = aws_organizations_account.dian_bot.id
  target_type = "AWS_ACCOUNT"
}

# jaime.admin -> AdministratorAccess en el resto de cuentas de Workloads.
resource "aws_ssoadmin_account_assignment" "workload_admin" {
  for_each = aws_organizations_account.workload

  instance_arn       = local.sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin.arn

  principal_id   = data.aws_identitystore_user.owner.user_id
  principal_type = "USER"

  target_id   = each.value.id
  target_type = "AWS_ACCOUNT"
}
