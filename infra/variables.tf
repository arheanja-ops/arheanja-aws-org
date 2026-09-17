# Emails de las cuentas (truco del + de Gmail: todo llega a taxopsa@gmail.com).
variable "account_emails" {
  description = "Email por cuenta futura (alias + de Gmail)."
  type        = map(string)
  default = {
    dian-bot        = "taxopsa+dianbot@gmail.com"
    investment-self = "taxopsa+investment@gmail.com"
    trip-covenas    = "taxopsa+covenas@gmail.com"
    taxops-prod     = "taxopsa+taxopsprod@gmail.com"
    taxops-dev      = "taxopsa+taxopsdev@gmail.com"
  }
}

# Regiones permitidas por el guardrail region-lock (SCP).
variable "allowed_regions" {
  description = "Regiones donde se permite operar. Servicios globales se exceptúan aparte."
  type        = list(string)
  default     = ["us-east-1"]
}

# Control de costos (Fase 1).
variable "budget_notification_email" {
  description = "Email que recibe alertas de anomalías de costo."
  type        = string
  default     = "taxopsa@gmail.com"
}
