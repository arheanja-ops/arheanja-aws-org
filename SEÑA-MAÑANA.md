# 📌 Seña / estado — actualizado 2026-09-20

## Estructura de cuentas
- `ai-platform-arheanja` (`080891698277`) — IA/agentes/bots + proyectos personales:
  DIAN-bot ✅, trip-coveñas ✅, (futuros: job-hunt-bot, matchstack).
- `taxops` (`562548008942`) — TaxOps prod + investment-self (aún sin migrar).
- management `786567028012` — se vacía al final.

## Hecho (2026-09-19/20)
- **Verificado**: job-hunt-bot y matchstack NO existen en AWS (nacerán en
  ai-platform cuando se construyan; hay repos locales pero sin infra desplegada).
- **trip-coveñas MIGRADO** a ai-platform y funcionando con datos en vivo:
  - https://covenas.taxopsapp.com → HTTP 200, CloudFront `d25bjcrw9n30z7`
    (`E1WUSE93CI7IOX`), API `4ykqwctvr7`, dashboard con datos reales.
  - Infra vieja destruida en management; management limpia de coveñas
    (Lambda, bucket, CloudFront, cert, secreto SSM — todo borrado).
  - Backend en `dianbot-tfstate-080891698277` key `trip-covenas/`.
  - Todo por CI/CD del repo `Portfolio-jaime/trip-covenas` (cuenta GitHub
    distinta; gh config `gh-trip-covenas`).
  - **delete_branch_on_merge activado** en ese repo.
- **Fixes/lecciones de la migración de coveñas**:
  - CNAME conflict: destruir CloudFront viejo Y borrar el registro DNS en
    Cloudflare antes de crear el nuevo (AWS valida contra DNS vivo).
  - Trust OIDC con comodines `repo:owner*/repo*:*` (IDs numéricos de GitHub).
  - Build del Lambda package en CI: `pip install` antes de terraform (el
    archive_file fallaba en runner limpio).
  - config.js apuntaba al API viejo → actualizado al nuevo.
  - SPREADSHEET_ID en repo var estaba mal (404) → corregido al real
    `1_O7dvVOfmimSJ9SQXYdQhlKehdvbAoctdDvbOMo3g74`.
  - PR #4 pendiente de merge (deja config.js consistente en el repo).

## Mañana — próximos pasos
1. **Mergear PR #4** de trip-covenas (config.js) — deja el repo consistente.
   Limpiar ramas viejas mergeadas (#2, #3) si se quiere.
2. **Limpiar CNAME validación ACM viejo** en Cloudflare (`_803425...covenas`,
   opcional, inofensivo).
3. **Migrar TaxOps prod → cuenta `taxops`** (`562548008942`). LO DELICADO:
   - DB en Neon (externa): solo re-apuntar DATABASE_URL, no migra.
   - Buckets `taxops-*-prod`: s3 sync a la cuenta nueva.
   - SQS `taxops-jobs-prod`: recrear + drenar la vieja antes de cortar.
   - Lambdas `taxops-api-prod`, `taxops-worker-prod`: recrear.
   - Secretos: TaxOps hoy los tiene en env vars de Lambda en texto plano →
     migrar a SSM SecureString ANTES/durante (no arrastrar el anti-patrón).
   - DNS `api.taxopsapp.com`, `app.taxopsapp.com`: cortar al final.
   - Ventana de mantenimiento. Bucket tfstate: `taxops11-tfstate-786567028012`.
4. **investment-self**: EN DESARROLLO — NO migrar hasta que estabilice.
5. **Vaciar management** una vez migrado TaxOps.

## Datos de referencia
- Org `o-k27om02vsy`, root `r-j9f1`, management `786567028012`.
- SSO instancia `ssoins-722353cec8cc0313`, store `d-90667809b5`, user `jaime.admin`.
- Perfiles CLI: `taxops-admin` (management), `ai-platform` (080891698277).
- Ambas cuentas hijas bajo OU Workloads (`ou-j9f1-gxoo9kci`), heredan 4 SCPs.
- SCP require-tags NO incluye s3:CreateBucket (S3 no soporta tag-on-create).
- Repos: `arheanja-ops/arheanja-aws-org`, `arheanja-ops/DIAN-bot`,
  `Portfolio-jaime/trip-covenas`.
