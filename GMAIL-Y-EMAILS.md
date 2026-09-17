# aws-org

Infraestructura como código de la **organización AWS multi-cuenta**. Gestiona
OUs, SCPs, cuentas y SSO. Ver el plan completo en
`DIAN-bot/docs/AWS-ORG-PLAN.md`.

**Premisa: todo gratis.** Organizations, OUs, SCPs, SSO y cuentas no tienen costo.

## Estado
- Fase 1 (fundación): OUs `Workloads`, `Sandbox`, `Security`.
- Backend de state: S3 `awsorg-tfstate-786567028012` + lock DynamoDB `awsorg-tflock`.

## Uso
```bash
export AWS_PROFILE=taxops-admin
terraform init
terraform plan     # revisar SIEMPRE antes de aplicar
terraform apply    # crea/actualiza org (por PR en producción)
```

## Emails de las cuentas — alias `+` de Gmail

Cada cuenta AWS necesita un email único. Usamos el truco del `+` de Gmail: todos
los alias llegan a `taxopsa@gmail.com` pero AWS los ve distintos.

| Cuenta | Email |
|---|---|
| dian-bot | `taxopsa+dianbot@gmail.com` |
| investment-self | `taxopsa+investment@gmail.com` |
| trip-covenas | `taxopsa+covenas@gmail.com` |
| taxops-prod | `taxopsa+taxopsprod@gmail.com` |
| taxops-dev | `taxopsa+taxopsdev@gmail.com` |

### Organizar en Gmail (labels + filtros) — recomendado

Para que las notificaciones de cada cuenta AWS queden ordenadas y no se pierdan:

1. **Crear un label por cuenta**: Gmail → Configuración → Etiquetas → *Crear
   etiqueta nueva* (ej. `AWS/dian-bot`, `AWS/taxops-prod`). Usar `AWS/` como
   prefijo crea una jerarquía anidada.
2. **Crear un filtro por alias**:
   - Gmail → barra de búsqueda → menú de filtros (icono deslizadores).
   - Campo **Para (To)**: `taxopsa+dianbot@gmail.com`
   - *Crear filtro* → marcar **Aplicar la etiqueta** `AWS/dian-bot` y
     (opcional) **Marcar como importante** / **No enviar a Spam**.
   - Repetir por cada alias.
3. **Sugerencia**: un filtro extra para `To: taxopsa+*@gmail.com` con label
   `AWS` general, y no archivar los de facturación/seguridad (root, budgets).

Así cada correo de AWS (verificación de cuenta, alertas de Budget, avisos de
seguridad) cae etiquetado por proyecto automáticamente.

> Nota: los correos críticos (root de cada cuenta, alertas de billing) conviene
> dejarlos visibles en Inbox, no auto-archivados.
