# 📌 SEÑA — Estado del proyecto AWS multi-cuenta (2026-09-23)

## 🎯 Objetivo general
Migrar todos los workloads personales desde la cuenta **management `786567028012`**
(anti-patrón: management + workloads mezclados) a **cuentas dedicadas por proyecto**
bajo AWS Organizations, con guardrails (SCPs), SSO, y todo como código por PR.
**Premisa dura: todo GRATIS / $0.**

## 🏗️ Estructura de cuentas (decidida y creada)
| Cuenta | ID | Contenido | Estado |
|---|---|---|---|
| management | `786567028012` | solo billing/org/SSO (se vacía al final) | tiene TaxOps viejo + investment-self |
| `ai-platform-arheanja` | `080891698277` | IA/agentes/bots | DIAN-bot ✅, coveñas ✅ |
| `taxops` | `562548008942` | TaxOps + investment-self | TaxOps en migración (5/8) |

Perfiles CLI: `taxops-admin` (786567028012), `ai-platform` (080891698277), `taxops` (562548008942).

---

## ✅ IMPLEMENTADO hasta ahora

### Gobernanza (repo arheanja-ops/arheanja-aws-org)
- Org `o-k27om02vsy`, root `r-j9f1`. OUs: Workloads, Sandbox, Security.
- **4 SCPs** en OU Workloads: region-lock (us-east-1), deny-expensive-services,
  require-tags (sin s3:CreateBucket), protect-org.
- **SSO permission sets**: AdministratorAccess, ReadOnly, Billing.
- **Cuentas creadas**: ai-platform-arheanja + taxops (bajo Workloads, heredan SCPs).
- Flujo GitOps: PR→plan→merge→apply con aprobación (environment). Repo es público
  para tener required reviewers gratis.

### DIAN-bot → ai-platform (✅ MIGRADO Y FUNCIONANDO)
- Infra recreada (ECR, Lambda, API GW, SSM, EventBridge), imagen, secretos, webhook.
- Infra vieja destruida en management. CI/CD apunta a cuenta nueva.
- **Mejoras extra**: `/consultar` siempre responde; heartbeats 7am/5pm L-V.
- Costo $0 (solo ~$0.03/mes ECR aceptado). Perfil local: `ai-platform`.

### trip-coveñas → ai-platform (✅ MIGRADO Y FUNCIONANDO)
- Lambda + API GW + S3 + CloudFront + ACM + dominio `covenas.taxopsapp.com`.
- Datos en vivo del Google Sheet OK. Infra vieja destruida.
- Repo `Portfolio-jaime/trip-covenas` (gh config `gh-trip-covenas`), delete-branch-on-merge ON.

### TaxOps → taxops (⏳ FASES 0-5 de 8)
Plan completo: `TaxOps-11/PLAN-MIGRACION-CUENTA.md`. Modo local, perfil `taxops`.
Repo: `/Users/jaime.henao/arheanja/Personal-enterprise/ABA-Projects/repo-andres/TaxOps-11`.
- **Fase 0-2**: perfil SSO, SCPs OK, bucket tfstate `taxops11-tfstate-562548008942`,
  backend/vars/workflow apuntados a cuenta nueva, imports.tf vaciado, init state vacío.
- **Fase 3** (base): ECR taxops-api, 7 secretos SSM `/taxops11/prod/*`, DynamoDB
  taxops-jobs-prod, SQS+DLQ, 3 roles OIDC, cost-reminders. Buckets S3 viejos borrados
  y recreados (nombres globales).
- **Fase 4**: imagen x86_64 (Tesseract) en ECR nuevo, tags latest+v3.
- **Fase 5**: Lambdas api+worker+FunctionURL+SQS mapping. **API FUNCIONA**:
  `/health → {status:ok, version:2.0.1, db:connected}` (DB Neon OK).
  Function URL: `https://ewcqa5dgblely6xxexabodfbce0kgtyz.lambda-url.us-east-1.on.aws/`
- **Bug arreglado**: null_resource roto del permiso Function URL (flag inexistente
  `--invoked-via-function-url`) → 403. Reemplazado por aws_lambda_permission nativo.

---

## ⏳ QUÉ FALTA

### TaxOps — Fases 6-8 (guía detallada: `TaxOps-11/CONTINUAR-MIGRACION.md`)
Requieren tus tokens:
- **Fase 6 — CDN**: ACM + CloudFront para `api.taxopsapp.com`.
  ⚠️ Antes: borrar el CNAME `api` viejo en Cloudflare (evita CNAMEAlreadyExists).
  Necesita `CLOUDFLARE_API_TOKEN`.
- **Fase 7 — Amplify**: frontend `app.taxopsapp.com` + reapuntar DNS `api`/`app` en
  Cloudflare. Necesita `CLOUDFLARE_API_TOKEN` + PAT GitHub (`TF_VAR_github_access_token`).
- **Fase 8 — Destruir infra vieja** en management 786567028012 (IRREVERSIBLE — hacer
  con el asistente).
- **CI/CD**: actualizar GitHub Variables `AWS_*_ROLE_ARN` a roles de 562548008942.

### Pendientes globales
- **Rotar secretos TaxOps** (DATABASE_URL, SECRET_KEY, GROQ_API_KEY, GOOGLE_CLIENT_SECRET,
  BOOTSTRAP_SECRET) — hoy commiteados en `terraform.tfvars.secret`. Tras migrar.
- **investment-self**: EN DESARROLLO, migrar a `taxops` cuando estabilice.
- **Vaciar management** por completo (tras TaxOps + investment-self).
- Limpiezas menores: CNAME validación ACM viejo de coveñas; PR #17 (aws-org, docs).

---

## ▶️ PRÓXIMO PASO INMEDIATO
Fase 6 (CDN de TaxOps). Bloqueada esperando decisión:
- **Opción A**: exportás `CLOUDFLARE_API_TOKEN` → aplico CDN completo (con DNS).
- **Opción B**: aplico solo recursos AWS del CDN (`-target`, sin Cloudflare) y vos
  hacés el DNS manual después.

## Datos de referencia
- Org o-k27om02vsy, root r-j9f1. SSO ssoins-722353cec8cc0313, store d-90667809b5.
- Dominios TaxOps: `api.taxopsapp.com` (CloudFront), `app.taxopsapp.com` (Amplify), DNS en Cloudflare.
- Repos: arheanja-ops/{arheanja-aws-org, DIAN-bot}, Portfolio-jaime/trip-covenas, TaxOps-11 (local).

---
## ⏭️ RETOMAR AQUÍ (2026-09-24)
Fase 6 lista para ejecutar. Confirmado:
- `.envrc` de TaxOps YA tiene CLOUDFLARE_API_TOKEN + TF_VAR_github_access_token (con valor).
- OJO: `.envrc` exporta AWS_PROFILE=taxops-admin (cuenta VIEJA). El apply debe correr
  con `AWS_PROFILE=taxops` EXPLÍCITO (cuenta nueva 562548008942).
- ÚNICO BLOQUEANTE: hacer `aws sso login --profile taxops` (estaba expirado).
Luego: Fase 6 = borrar CNAME `api` viejo en Cloudflare → `AWS_PROFILE=taxops terraform apply -var-file=terraform.tfvars.secret -target=module.cdn` → verificar /health por dominio crudo CloudFront.

---
## ⏭️ RETOMAR AQUÍ (2026-09-24) — Fase 6 a medias
Avance de hoy en Fase 6 (CDN de TaxOps):
- ✅ ACM cert para api.taxopsapp.com creado y validado (cuenta 562548008942).
- ✅ Records Cloudflare de validación creados.
- ✅ Borré el CNAME `api` viejo en Cloudflare (apuntaba a d19jqrsigzoeds.cloudfront.net).
- ❌ CloudFront nuevo NO se pudo crear: CNAMEAlreadyExists — el CloudFront VIEJO
  (d19jqrsigzoeds, cuenta 786567028012) TODAVÍA tiene el alias api.taxopsapp.com
  en la distribución (no basta borrar el DNS, hay que soltar el alias del recurso).

BLOQUEANTE mañana:
1. `aws sso login --profile taxops-admin` (cuenta vieja, expiró).
2. Soltar el alias `api.taxopsapp.com` del CloudFront viejo d19jqrsigzoeds
   (o deshabilitarlo/destruirlo — adelanto de Fase 8). CloudFront tarda ~15min en actualizar.
3. Reintentar: `AWS_PROFILE=taxops terraform apply -var-file=terraform.tfvars.secret -target=module.cdn`
   (desde infra/environments/prod, con .envrc sourced para CLOUDFLARE_API_TOKEN).
4. Verificar /health por el dominio crudo del CloudFront nuevo (terraform output api_domain).
Luego seguir Fase 7 (Amplify + DNS) y Fase 8.

Datos: zone Cloudflare taxopsapp.com = 788cc5fa6cfae72a7db453f20323cccb.
Tokens ya en .envrc (CLOUDFLARE_API_TOKEN + TF_VAR_github_access_token).

---
## ✅ CIERRE 2026-09-28 — TaxOps MIGRADO (8/8 fases)
TaxOps 100% en cuenta taxops (562548008942): api/app.taxopsapp.com OK, infra vieja
destruida en management. PR infra: ABA-projects/TaxOps-11 #57. GitHub Variables
AWS_*_ROLE_ARN actualizadas a roles 562548008942. Build Amplify SUCCEED.
Limpieza: CNAME validación ACM huérfano de coveñas borrado; recreado el CNAME
de validación ACTIVO de coveñas (_803425c3, faltaba → renovación del cert
habría fallado). CONTINUAR-MIGRACION.md borrado (ejecutado).

### Único workload que queda en la management 786567028012:
- investment-self (dev-auth, dev-api) — EN DESARROLLO, migrar a taxops cuando estabilice.

### PENDIENTE (sesión dedicada):
- ROTAR secretos TaxOps (DATABASE_URL/SECRET_KEY/GROQ_API_KEY/GOOGLE_CLIENT_SECRET/
  BOOTSTRAP_SECRET) en Neon/Google/Groq + sacar de terraform.tfvars.secret + purgar git.
- Mergear PR #57 (TaxOps infra) y validar el CI/CD con el pipeline.
