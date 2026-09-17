# 📌 Seña / próximo paso — anotado 2026-09-17

## Mañana: migrar el workload de DIAN-bot a la cuenta nueva `dian-bot` (`080891698277`)

Se hace desde el repo **DIAN-bot** (`/Users/jaime.henao/arheanja/personal-projects/DIAN-bot`),
**NO** desde `arheanja-aws-org`.

### Checklist
- [ ] Apuntar el Terraform de `DIAN-bot/infra` a la cuenta `dian-bot`
      (backend + provider con `AWS_PROFILE=dian-bot`).
- [ ] Recrear ECR + Lambda + EventBridge + API Gateway + SSM en la cuenta nueva.
- [ ] Re-cargar los secretos de Telegram en el SSM de la cuenta nueva
      (`telegram_bot_token`, `chat_id`, `webhook_secret`) con `put-parameter`.
- [ ] Re-push de la imagen del contenedor al ECR de la cuenta nueva.
- [ ] Re-registrar el webhook de Telegram al nuevo API Gateway.
- [ ] Actualizar el `.envrc` de DIAN-bot para exportar `AWS_PROFILE=dian-bot`.
- [ ] Verificar (dry-run / `/consultar`) contra la cuenta nueva.
- [ ] Destruir la infra vieja en la management account `786567028012`.

### Contexto (estado al 2026-09-17)
- Cuenta `dian-bot` ya creada, `ACTIVE`, bajo la OU `Workloads` (hereda las 4
  SCPs: region-lock, deny-expensive-services, require-tags, protect-org).
- Acceso SSO admin para `jaime.admin` ya asignado. Perfil CLI local `dian-bot`
  configurado y verificado (`aws sts get-caller-identity` OK).
- Riesgo: bajo (casi stateless). Downtime: minutos. Costo: **$0**.

### Datos de referencia
- Repo org: `arheanja-ops/arheanja-aws-org`.
- Management account: `786567028012`. Org `o-k27om02vsy`, root `r-j9f1`.
- SSO: instancia `ssoins-722353cec8cc0313`, identity store `d-90667809b5`.

### Estado Fase 2 al cierre de hoy
- `dian-bot` creada y accesible.
- Otras 4 cuentas (`investment-self`, `trip-covenas`, `taxops-dev`,
  `taxops-prod`) en el **PR #11**, pendiente de merge + aprobación del apply.
