resource "google_logging_project_sink" "backend" {
  name        = "${var.project}-backend-sink"
  project     = var.project_id
  destination = "logging.googleapis.com/projects/${var.project_id}/locations/global/buckets/_Default"
  filter      = "resource.type=\"cloud_run_revision\" AND resource.labels.service_name=\"${var.project}-backend\""

  unique_writer_identity = true
}

# ── Uptime Check ──────────────────────────────────────────────────────────────
resource "google_monitoring_uptime_check_config" "backend_health" {
  display_name = "${var.project} Backend Health"
  project      = var.project_id
  timeout      = "10s"
  period       = "10s"

  http_check {
    path         = "/health"
    port         = 443
    use_ssl      = true
    validate_ssl = true
  }

  monitored_resource {
    type = "uptime_url"
    labels = {
      project_id = var.project_id
      host       = var.cloudrun_domain
    }
  }
}

# ── Alert Policies ────────────────────────────────────────────────────────────
resource "google_monitoring_alert_policy" "cloudrun_cpu" {
  display_name = "${var.project} Cloud Run CPU High"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "Cloud Run CPU utilization > 70%"
    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/container/cpu/utilizations\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 0.7
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_PERCENTILE_99"
      }
    }
  }

  notification_channels = var.notification_channel_ids
  alert_strategy {
    auto_close = "1800s"
  }
}

resource "google_monitoring_alert_policy" "cloudrun_errors" {
  display_name = "${var.project} Cloud Run Error Rate"
  project      = var.project_id
  combiner     = "OR"

  conditions {
    display_name = "5xx error rate > 1%"
    condition_threshold {
      filter          = "resource.type=\"cloud_run_revision\" AND metric.type=\"run.googleapis.com/request_count\" AND metric.labels.response_code_class=\"5xx\""
      duration        = "60s"
      comparison      = "COMPARISON_GT"
      threshold_value = 10
      aggregations {
        alignment_period   = "60s"
        per_series_aligner = "ALIGN_SUM"
      }
    }
  }

  notification_channels = var.notification_channel_ids
}

# ── Notification Channel (email placeholder) ─────────────────────────────────
resource "google_monitoring_notification_channel" "email" {
  display_name = "Sauda Ops Email"
  project      = var.project_id
  type         = "email"

  labels = {
    email_address = var.alert_email
  }
}
