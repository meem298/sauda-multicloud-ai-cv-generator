output "cloudrun_url" {
  description = "Cloud Run HTTPS endpoint — use as Route 53 weighted record value"
  value       = google_cloud_run_v2_service.backend.uri
}

output "cloudrun_hostname" {
  description = "Hostname only (no https://) — use in Route 53 CNAME record"
  value       = replace(google_cloud_run_v2_service.backend.uri, "https://", "")
}

output "artifact_registry_url" {
  value = "${var.region}-docker.pkg.dev/${var.project_id}/sauda-backend"
}
