# Fase 1 (resto) — Control de costos.
# COSTO: $0. Cost Anomaly Detection es gratis ("available at no additional
# charge", AWS).
#
# NOTA: no se crea un budget aquí. La cuenta ya tiene `account-zero-spend`
# ($1/mes, alertas a >$0.01 / 50% / 80% / forecast 100%), más completo que un
# duplicado. AWS solo da 2 budgets gratis por cuenta, así que no gastamos ese
# slot en algo redundante. Los budgets per-cuenta llegan en la Fase 2 (cada
# cuenta nueva trae sus propios 2 budgets gratis).

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
