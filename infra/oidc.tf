# Proveedor OIDC de GitHub Actions en la management account.
#
# El workflow (terraform.yml) asume el rol arheanja-aws-org-deploy por OIDC; la politica
# de confianza de ese rol apunta a este proveedor. Sin el, el paso "Credenciales AWS (OIDC)"
# falla con "The web identity token provided could not be validated".
#
# HISTORIA: se creo a mano y se borro por error el 2026-09-18 (CloudTrail:
# DeleteOpenIDConnectProvider por jaime.admin). Al no estar en Terraform, nadie lo noto
# hasta que fallo un PR. Ahora queda declarado aqui.
#
# BOOTSTRAP: el pipeline depende de este recurso para autenticarse, asi que su PRIMERA
# aplicacion se hace localmente con taxops-admin. Despues lo gestiona el pipeline normal.
#
# COSTO: $0. Los proveedores OIDC de IAM no se cobran.
#
# thumbprint_list se omite: para token.actions.githubusercontent.com AWS valida contra su
# almacen de CA de confianza y ya no usa el thumbprint (opcional desde provider 5.81).

resource "aws_iam_openid_connect_provider" "github" {
  url            = "https://token.actions.githubusercontent.com"
  client_id_list = ["sts.amazonaws.com"]

  lifecycle {
    prevent_destroy = true
  }
}

# Permisos de SOLO LECTURA para el rol del pipeline sobre lo que declara este archivo.
# Terraform refresca cada recurso del estado en cada plan; sin estos permisos el plan
# falla con AccessDenied (iam:GetOpenIDConnectProvider). Es una politica inline ADICIONAL:
# no toca la politica existente `org-deploy` (creada a mano) ni el rol.
#
# Deliberadamente sin permisos de escritura: el pipeline no debe poder modificar el
# proveedor del que depende su propia autenticacion. Esos cambios se hacen con taxops-admin.
data "aws_caller_identity" "current" {}

data "aws_iam_policy_document" "org_deploy_iam_read" {
  statement {
    sid    = "ReadGithubOidcProvider"
    effect = "Allow"
    actions = [
      "iam:GetOpenIDConnectProvider",
      "iam:ListOpenIDConnectProviderTags",
    ]
    resources = [aws_iam_openid_connect_provider.github.arn]
  }

  statement {
    sid       = "ReadOwnInlinePolicy"
    effect    = "Allow"
    actions   = ["iam:GetRolePolicy"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/arheanja-aws-org-deploy"]
  }
}

resource "aws_iam_role_policy" "org_deploy_iam_read" {
  name   = "org-deploy-iam-read"
  role   = "arheanja-aws-org-deploy"
  policy = data.aws_iam_policy_document.org_deploy_iam_read.json
}

output "github_oidc_provider_arn" {
  description = "ARN del proveedor OIDC de GitHub Actions."
  value       = aws_iam_openid_connect_provider.github.arn
}
