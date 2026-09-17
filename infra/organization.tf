# Fase 1 — Unidades organizativas (OUs).
# Crear OUs es GRATIS y no afecta a ninguna cuenta ni workload existente.
# La cuenta actual (management) permanece bajo la raíz hasta migrar TaxOps.

locals {
  root_id = data.aws_organizations_organization.current.roots[0].id
}

resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = local.root_id
}

resource "aws_organizations_organizational_unit" "sandbox" {
  name      = "Sandbox"
  parent_id = local.root_id
}

resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
  parent_id = local.root_id
}

output "ou_workloads_id" {
  value = aws_organizations_organizational_unit.workloads.id
}

output "ou_sandbox_id" {
  value = aws_organizations_organizational_unit.sandbox.id
}

output "ou_security_id" {
  value = aws_organizations_organizational_unit.security.id
}
