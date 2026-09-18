# Fase 1 (resto) — Service Control Policies (guardrails).
#
# Las SCPs son GRATIS. El root r-j9f1 hoy tiene PolicyTypes vacío: hay que
# habilitar el tipo SERVICE_CONTROL_POLICY antes de poder adjuntar SCPs. La
# organización ya existe (o-k27om02vsy) y se gestiona vía data source; para
# habilitar el policy type se adopta al state con un import block (Terraform
# 1.5+) y NO se recrea.
#
# Guardrails DENY (sobre el FullAWSAccess heredado). Adjuntas a la OU Workloads;
# Sandbox recibe solo region-lock (experimentación más libre pero acotada).
# El tagging lo aporta default_tags del provider (main.tf).

import {
  to = aws_organizations_organization.this
  id = "o-k27om02vsy"
}

resource "aws_organizations_organization" "this" {
  feature_set = "ALL"

  enabled_policy_types = ["SERVICE_CONTROL_POLICY"]

  # Trusted access EXACTO al ya habilitado hoy (sso + access-analyzer), para no
  # cambiarlo al adoptar la org. CloudTrail org se añadirá con la OU Security.
  aws_service_access_principals = [
    "sso.amazonaws.com",
    "access-analyzer.amazonaws.com",
    # Account Management: necesario para renombrar/gestionar cuentas miembro por
    # IaC (account:PutAccountName). Habilitado 2026-09-18.
    "account.amazonaws.com",
  ]

  lifecycle {
    prevent_destroy = true
  }
}

# --- SCP 1: Region lock (deny fuera de us-east-1, salvo servicios globales) ---
data "aws_iam_policy_document" "region_lock" {
  statement {
    sid       = "DenyOutsideAllowedRegions"
    effect    = "Deny"
    resources = ["*"]

    condition {
      test     = "StringNotEquals"
      variable = "aws:RequestedRegion"
      values   = var.allowed_regions
    }

    # SCP: un statement usa Action O NotAction, nunca ambos. Denegamos todo
    # (fuera de la región permitida) EXCEPTO estos servicios globales.
    not_actions = [
      "iam:*",
      "organizations:*",
      "route53:*",
      "cloudfront:*",
      "support:*",
      "sts:*",
      "waf:*",
      "wafv2:*",
      "globalaccelerator:*",
      "budgets:*",
      "ce:*",
      "cur:*",
    ]
  }
}

resource "aws_organizations_policy" "region_lock" {
  name        = "region-lock"
  description = "Deniega acciones fuera de ${join(",", var.allowed_regions)} (excepto servicios globales)."
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.region_lock.json

  # Espera a que el tipo SCP quede habilitado en el root antes de crear/adjuntar.
  depends_on = [aws_organizations_organization.this]
}

# --- SCP 2: Denegar servicios caros por defecto (rompen el free tier) ---
data "aws_iam_policy_document" "deny_expensive" {
  statement {
    sid    = "DenyExpensiveServices"
    effect = "Deny"
    actions = [
      "rds:CreateDBInstance",
      "rds:CreateDBCluster",
      "redshift:CreateCluster",
      "sagemaker:CreateNotebookInstance",
      "sagemaker:CreateEndpoint",
      "es:CreateElasticsearchDomain",
      "es:CreateDomain",
      "elasticache:CreateCacheCluster",
      "ec2:CreateNatGateway",
      "globalaccelerator:CreateAccelerator",
    ]
    resources = ["*"]
  }

  # Bloquear familias EC2 grandes (permitir solo t2/t3/t3a/t4g).
  statement {
    sid       = "DenyLargeEC2"
    effect    = "Deny"
    actions   = ["ec2:RunInstances"]
    resources = ["arn:aws:ec2:*:*:instance/*"]

    condition {
      test     = "ForAnyValue:StringNotLike"
      variable = "ec2:InstanceType"
      values   = ["t2.*", "t3.*", "t3a.*", "t4g.*"]
    }
  }
}

resource "aws_organizations_policy" "deny_expensive" {
  name        = "deny-expensive-services"
  description = "Deniega RDS, Redshift, SageMaker, ES, ElastiCache, NAT GW y EC2 grandes."
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.deny_expensive.json

  depends_on = [aws_organizations_organization.this]
}

# --- SCP 3: Exigir tag Project al crear recursos clave ---
data "aws_iam_policy_document" "require_tags" {
  statement {
    sid    = "RequireProjectTag"
    effect = "Deny"
    actions = [
      "ec2:RunInstances",
      "lambda:CreateFunction",
      "s3:CreateBucket",
      "dynamodb:CreateTable",
    ]
    resources = ["*"]

    condition {
      test     = "Null"
      variable = "aws:RequestTag/Project"
      values   = ["true"]
    }
  }
}

resource "aws_organizations_policy" "require_tags" {
  name        = "require-tags"
  description = "Exige el tag Project al crear EC2, Lambda, S3, DynamoDB."
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.require_tags.json

  depends_on = [aws_organizations_organization.this]
}

# --- SCP 4: Proteger la organización ---
data "aws_iam_policy_document" "protect_org" {
  statement {
    sid    = "ProtectOrganization"
    effect = "Deny"
    actions = [
      "organizations:LeaveOrganization",
      "organizations:DeleteOrganization",
      "organizations:RemoveAccountFromOrganization",
      "cloudtrail:StopLogging",
      "cloudtrail:DeleteTrail",
      "account:CloseAccount",
    ]
    resources = ["*"]
  }
}

resource "aws_organizations_policy" "protect_org" {
  name        = "protect-org"
  description = "Impide salir de la org, borrar CloudTrail o cerrar cuentas desde cuentas hijas."
  type        = "SERVICE_CONTROL_POLICY"
  content     = data.aws_iam_policy_document.protect_org.json

  depends_on = [aws_organizations_organization.this]
}

# --- Attachments ---
# Workloads: guardrails completos.
resource "aws_organizations_policy_attachment" "workloads_region_lock" {
  policy_id = aws_organizations_policy.region_lock.id
  target_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_policy_attachment" "workloads_deny_expensive" {
  policy_id = aws_organizations_policy.deny_expensive.id
  target_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_policy_attachment" "workloads_require_tags" {
  policy_id = aws_organizations_policy.require_tags.id
  target_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_policy_attachment" "workloads_protect_org" {
  policy_id = aws_organizations_policy.protect_org.id
  target_id = aws_organizations_organizational_unit.workloads.id
}

# Sandbox: solo region-lock.
resource "aws_organizations_policy_attachment" "sandbox_region_lock" {
  policy_id = aws_organizations_policy.region_lock.id
  target_id = aws_organizations_organizational_unit.sandbox.id
}
