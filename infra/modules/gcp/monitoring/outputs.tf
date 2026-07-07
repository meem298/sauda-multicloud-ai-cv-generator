output "notification_channel_id" {
  value = google_monitoring_notification_channel.email.name
}

output "uptime_check_id" {
  value = google_monitoring_uptime_check_config.backend_health.uptime_check_id
}
