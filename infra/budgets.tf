# Fase 1 (resto) — Control de costos (garantizar el "gratis").
# COSTO: AWS Budgets da 2 budgets gratis por cuenta; Cost Anomaly Detection es
# gratis.

# --- Budget mensual de $1 con alertas al 80% y 100% ---
resource "aws_budgets_budget" "monthly_zero" {
  name         = "arheanja-org-monthly-zero"
  budget_type  = "COST"
  limit_amount = tostring(var.monthly_budget_usd)
  limit_unit   = "USD"
  time_unit    = "MONTHLY"

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_notification_email]
  }

  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_email_addresses = [var.budget_notification_email]
  }
}

# --- Cost Anomaly Detection (gratis) a nivel de servicio ---
resource "aws_ce_anomaly_monitor" "services" {
  name              = "arheanja-org-services-monitor"
  monitor_type      = "DIMENSIONAL"
  monitor_dimension = "SERVICE"
}

resource "aws_ce_anomaly_subscription" "alerts" {
  name             = "arheanja-org-anomaly-alerts"
  frequency        = "DAILY"
  monitor_arn_list = [aws_ce_anomaly_monitor.services.arn]

  subscriber {
    type    = "EMAIL"
    address = var.budget_notification_email
  }

  # Alertar solo si el impacto absoluto de la anomalía es >= $1.
  threshold_expression {
    dimension {
      key           = "ANOMALY_TOTAL_IMPACT_ABSOLUTE"
      match_options = ["GREATER_THAN_OR_EQUAL"]
      values        = ["1"]
    }
  }
}
