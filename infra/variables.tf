# Emails de las cuentas (truco del + de Gmail: todo llega a taxopsa@gmail.com).
variable "account_emails" {
  description = "Email por cuenta."
  type        = map(string)
  default = {
    # ai-platform conserva el email con que se creó la cuenta (ex dian-bot):
    # cambiar el email de una cuenta ya creada es un proceso aparte de AWS.
    ai-platform = "taxopsa+dianbot@gmail.com"
    taxops      = "taxopsa+taxops@gmail.com"
  }
}

# Regiones permitidas por el guardrail region-lock (SCP).
variable "allowed_regions" {
  description = "Regiones donde se permite operar. Servicios globales se exceptúan aparte."
  type        = list(string)
  default     = ["us-east-1"]
}
