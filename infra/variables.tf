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
