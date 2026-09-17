# arheanja-aws-org

Landing zone: gobernanza de la **organización AWS multi-cuenta** (OUs, SCPs,
cuentas, SSO). Repo padre transversal a todos los proyectos.

**Premisa: todo gratis.** Organizations, OUs, SCPs, SSO y cuentas no cuestan.

## Estructura
```
infra/
  main.tf           backend (S3+DynamoDB) + provider
  organization.tf   OUs (Workloads, Sandbox, Security)
  variables.tf      emails de cuentas (alias + de Gmail)
scripts/            plan, apply, aws-login, gh-login
.github/workflows/  terraform.yml (plan en PR, apply con aprobación)
GMAIL-Y-EMALS.md    guía de labels/filtros para los alias de correo
```

## Uso local
```bash
cp .envrc.example .envrc && direnv allow
./scripts/aws-login.sh
./scripts/plan.sh          # revisar antes de aplicar
```

## CI/CD
- **PR** → `terraform plan` (comentado en el PR).
- **Merge a main** → `apply` con **aprobación manual** (environment `org-apply`).
- Deploy por **OIDC** (rol `arheanja-aws-org-deploy`), sin llaves.

## Estado actual
- Fase 1: OUs `Workloads`, `Sandbox`, `Security`.
- State: S3 `awsorg-tfstate-786567028012`, key `organization/`, lock DynamoDB
  `awsorg-tflock`.

## Roadmap
Ver `DIAN-bot/docs/AWS-ORG-PLAN.md`: SCPs, cuentas por proyecto, migración
(DIAN-bot piloto → … → TaxOps), seguridad. Todo gratis.
