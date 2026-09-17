# Changelog — gobernanza AWS org

Bitácora de cambios de infraestructura/gobernanza. No es un changelog de
librería (sin SemVer); cada entrada es una sesión de trabajo real sobre la
organización AWS o el repo.

## 2026-09-16 — Fase 0 + arranque de Fase 1

### Fase 0 (preparación)
- Definidos los emails alias por cuenta futura (truco `+` de Gmail sobre
  `taxopsa@gmail.com`): `dian-bot`, `investment-self`, `trip-covenas`,
  `taxops-dev`, `taxops-prod` (ver `infra/variables.tf`).
- Repo `arheanja-aws-org` publicado en GitHub (`arheanja-ops/arheanja-aws-org`),
  con el scaffold inicial: OUs (`organization.tf`), backend Terraform, direnv,
  workflow de CI/CD.
  - El primer commit quedó con el autor equivocado (email de trabajo, `@ba.com`)
    porque el repo vivía fuera de `personal-projects/` y no heredaba
    `.gitconfig-personal`. Se corrigió el autor (`--amend --reset-author`) a
    `jaimehenao8126@outlook.com` antes de publicarlo.
  - Como el remoto estaba completamente vacío (sin `main`), el primer push
    fue directo a `main` (sin PR) — no había nada que proteger todavía. Todo
    cambio posterior sí va por PR.
- MFA en el root de la management account (`786567028012`) verificado ya
  activo (`aws iam get-account-summary` → `AccountMFAEnabled=1`).
- Repo movido de `~/arheanja/arheanja-aws-org` a
  `personal-projects/arheanja-aws-org` para heredar el aislamiento de
  credenciales (`AWS_PROFILE=taxops-admin`, `GH_CONFIG_DIR` propio) que ya usan
  los demás proyectos personales. Copia vieja eliminada tras confirmar que
  todo estaba pusheado.

### CI/CD de infra (PR #1, #2)
- **PR #1** — `required_reviewers` en GitHub Environments es una feature paga
  para repos privados (rompería la premisa de $0). Se reemplazó el gate de
  aprobación por `apply` manual (`workflow_dispatch`): el `plan` sigue
  automático en cada PR, pero nadie puede disparar el `apply` salvo el dueño
  del repo desde el botón "Run workflow".
  - De paso, se migró el backend Terraform de `dynamodb_table` (deprecado) a
    `use_lockfile = true` (locking nativo de S3, Terraform ≥ 1.11).
  - Se creó el environment `org-apply` y el secret `AWS_ORG_ROLE_ARN` (a nivel
    repo y del environment) en GitHub.
- **Incidente**: el primer run tras mergear el PR #1 falló con
  `Error acquiring the state lock` (lock huérfano en S3, dos workflows casi
  simultáneos — el del PR y el del push a `main`). El job quedó marcado como
  "success" porque el paso de plan usaba `terraform plan | tee plan.txt` sin
  `set -o pipefail`, lo que ocultaba el exit code real de Terraform.
- **PR #2** — corrige el pipefail (el job ahora sí falla en rojo si Terraform
  falla) y actualiza todas las GitHub Actions a sus últimas majors con soporte
  nativo de Node 24 (`checkout@v7`, `upload-artifact@v7`,
  `download-artifact@v8`, `configure-aws-credentials@v6`,
  `setup-terraform@v4`), ya que Node 20 fue deprecado por GitHub.
  - Con el pipefail corregido, apareció el error real subyacente: al rol IAM
    `arheanja-aws-org-deploy` le faltaba `s3:DeleteObject` para poder soltar
    el lock nativo de S3 (su policy inline `org-deploy` seguía escrita para el
    backend viejo de DynamoDB). Se corrigió la policy: se agregó
    `s3:DeleteObject` sobre el bucket de tfstate y se eliminó el bloque de
    permisos DynamoDB ya no usado.
  - Se liberaron manualmente (`terraform force-unlock`) dos locks huérfanos
    dejados por los runs fallidos antes de reintentar.
- Se activó `delete_branch_on_merge` en el repo (config de GitHub, gratis).

### Fase 1 — aplicada
- `terraform plan` corrido contra la organización real (`o-k27om02vsy`, raíz
  `r-j9f1`): confirmó 3 recursos a crear (`Workloads`, `Sandbox`, `Security`),
  0 a cambiar, 0 a destruir.
- `apply` disparado manualmente vía `workflow_dispatch` en Actions. Resultado
  verificado directo en AWS (no solo en el log del workflow):
  - `Workloads` → `ou-j9f1-gxoo9kci`
  - `Sandbox` → `ou-j9f1-o7twnsfh`
  - `Security` → `ou-j9f1-ueol9xss`
- Costo: $0 (AWS Organizations no cobra por OUs). Ningún workload existente
  fue tocado — las cuentas siguen todas bajo la raíz hasta la Fase 2
  (creación de cuentas nuevas y migración por proyecto).

## 2026-09-17 — Fase 1 (resto): SCPs + permission sets + control de costos

Aporta lo que faltaba de la Fase 1 del plan maestro (guardrails, SSO, budgets).
Todo GRATIS. Entregado por PR; el `apply` se dispara manual (`workflow_dispatch`).

### SCPs (`infra/scps.tf`)
- Se habilita el tipo `SERVICE_CONTROL_POLICY` en el root `r-j9f1` (hoy tenía
  `PolicyTypes` vacío). La organización `o-k27om02vsy` se **adopta** al state
  con un `import` block (Terraform 1.5+) — no se recrea. `prevent_destroy` y
  `aws_service_access_principals` fijados a lo ya habilitado (`sso`,
  `access-analyzer`) para no tocar el trusted access.
- 4 guardrails DENY: `region-lock` (fuera de us-east-1, salvo servicios
  globales), `deny-expensive-services` (RDS, Redshift, SageMaker, ES,
  ElastiCache, NAT GW, EC2 grandes), `require-tags` (exige tag `Project`),
  `protect-org` (impide salir de la org / borrar CloudTrail / cerrar cuentas).
- Adjuntas a la OU `Workloads`; `Sandbox` recibe solo `region-lock`.

### Permission sets SSO (`infra/permission_sets.tf`)
- `AdministratorAccess` existente (`ps-72236cd8d2569a6b`) **adoptado** vía
  `import`; se le añade `description` (cambio in-place, no toca sus políticas).
- Nuevos: `ReadOnly` (auditoría) y `Billing` (costos), con sus managed policies.

### Control de costos (`infra/budgets.tf`)
- Cost Anomaly Detection (monitor por servicio + suscripción diaria, umbral $1).
  Gratis ("available at no additional charge", AWS).
- **No se crea budget**: la cuenta ya tiene `account-zero-spend` ($1/mes, alertas
  a >$0.01 / 50% / 80% / forecast 100%), más completo que el que se había
  propuesto. AWS solo da **2 budgets gratis por cuenta**; no se gasta ese slot en
  un duplicado. Los budgets per-cuenta llegan en la Fase 2.

### Auditoría de costo (premisa dura $0)
Cada recurso del PR verificado contra el pricing oficial:
- SCPs + attachments + habilitar SCP type: **$0** (Organizations no cobra).
- Permission sets SSO + managed policy attachments: **$0** (Identity Center gratis).
- Cost Anomaly Detection: **$0**.
- Se retiró el único recurso con potencial de costo futuro (2º budget) por
  redundante. Total del PR: **$0**, sin consumir slots gratis reutilizables.

### Rol OIDC de deploy — permisos ampliados
- El rol `arheanja-aws-org-deploy` solo tenía `organizations:*` + S3 state, lo
  que habría hecho fallar el `apply` de permission sets y budgets con
  AccessDenied. Se amplió su policy inline `org-deploy` (additivo, no quita
  nada): `+sso:* +sso-admin:* +identitystore:*` y `+budgets:* +ce:*`.

### Verificación (local, `AWS_PROFILE=taxops-admin`)
- `terraform fmt` sin cambios, `validate` OK.
- `terraform plan` real contra la org: **`2 to import, 16 to add, 2 to change,
  0 to destroy`**. Las 3 OUs NO aparecen entre los cambios → cero drift. Los 2
  in-place son benignos (org: solo `+SERVICE_CONTROL_POLICY`; admin PS: solo
  `+description`). Nada se destruye.

### Premisa de costo
$0: SCPs, SSO, permission sets, Budgets (2 gratis/cuenta) y Cost Anomaly
Detection son gratis.

### Premisa de costo
Todo lo anterior es $0: cambios de código, config de GitHub (environments,
secrets, delete-branch-on-merge), políticas IAM, y el `plan`/lecturas de
Terraform no crean ni modifican recursos facturables. Ver
`DIAN-bot/docs/AWS-ORG-PLAN.md` sección 12 para el resumen de costos del plan
completo.
