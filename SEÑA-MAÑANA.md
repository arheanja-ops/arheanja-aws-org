# 📌 Seña / estado — actualizado 2026-09-18

## Hecho hoy (2026-09-18)
- **Estructura de cuentas decidida** (pocas cuentas, alineadas a proyectos):
  - `ai-platform-arheanja` (`080891698277`) — IA/agentes/bots (DIAN-bot,
    job-hunt-bot, matchstack).
  - `taxops` (`562548008942`) — TaxOps-11 + investment-self.
  - management `786567028012` — solo billing/org/SSO (se vacía al final).
- **DIAN-bot MIGRADO** a `ai-platform-arheanja` y operativo:
  - Infra recreada (22 recursos), imagen arm64, secretos, webhook re-registrado.
  - Infra vieja destruida en la management + bucket tfstate viejo borrado.
  - CI/CD (OIDC + secrets del repo) apuntando a la cuenta nueva; apply verde.
  - Perfil CLI local renombrado a `ai-platform`.
- **Costos cuenta IA**: budget `ai-platform-zero-spend` (alerta >$0.01), $0
  actual. Único costo aceptado: ~$0.03/mes por imagen ECR (807MB > 500MB free).
- **Fixes en el camino**: SCP `require-tags` sin `s3:CreateBucket` (S3 no soporta
  tag-on-create); trusted access de Account Management habilitado (para rename);
  rol OIDC de DIAN-bot ampliado (infra + budgets).
- Aclarado: las regiones `eu-*` que aparecen son solo "habilitadas por defecto";
  no hay recursos ni costo ahí, y la SCP `region-lock` bloquea fuera de us-east-1.

## Mañana — próximos pasos (orden sugerido)
1. **Verificar job-hunt-bot y matchstack**: ¿ya existen en AWS y dónde? Si no
   existen aún, nacen directo en `ai-platform-arheanja` (no hay migración).
   Si están en la management, migrarlos (patrón ya probado con DIAN-bot).
2. **Migrar TaxOps-11 + investment-self → cuenta `taxops`** (`562548008942`).
   Lo delicado: TaxOps es producción (DB en Neon = solo re-apuntar DATABASE_URL,
   no migra; buckets con s3 sync; SQS recrear+drenar; DNS al final; secretos a
   SSM antes). Ventana de mantenimiento. Proyecto dedicado.
3. **Vaciar la management** `786567028012` una vez no queden workloads.

## Datos de referencia
- Org `o-k27om02vsy`, root `r-j9f1`, management `786567028012`.
- SSO: instancia `ssoins-722353cec8cc0313`, store `d-90667809b5`, user
  `jaime.admin`. Perfiles CLI: `taxops-admin` (management), `ai-platform` (IA).
- Repos: `arheanja-ops/arheanja-aws-org` (gobernanza), `arheanja-ops/DIAN-bot`.
- Cuenta IA `ai-platform-arheanja` = `080891698277`. Cuenta `taxops` =
  `562548008942`. Ambas bajo OU Workloads (`ou-j9f1-gxoo9kci`), heredan 4 SCPs.
- Rol OIDC DIAN-bot: `arn:aws:iam::080891698277:role/dianbot-github-deploy`.
- tfstate DIAN-bot: `dianbot-tfstate-080891698277` (use_lockfile).
