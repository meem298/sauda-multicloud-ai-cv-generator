output "cloudrun_sa_email" {
  value = google_service_account.cloudrun.email
}

output "armor_policy_id" {
  value = google_compute_security_policy.main.id
}

output "armor_policy_self_link" {
  value = google_compute_security_policy.main.self_link
}

output "jwt_secret_id" {
  value = google_secret_manager_secret.jwt_secret.secret_id
}

output "vertex_ai_key_secret_id" {
  value = google_secret_manager_secret.vertex_ai_key.secret_id
}

output "jwt_secret_version" {
  value = google_secret_manager_secret_version.jwt_secret.name
}

output "vertex_ai_key_version" {
  value = google_secret_manager_secret_version.vertex_ai_key.name
}
