resource "google_redis_instance" "main" {
  name               = "${var.project}-redis-${var.environment}"
  tier               = "STANDARD_HA"
  memory_size_gb     = var.memory_size_gb
  region             = var.region
  project            = var.project_id
  redis_version      = "REDIS_7_0"
  authorized_network = var.network_id
  connect_mode       = "PRIVATE_SERVICE_ACCESS"
  display_name       = "Sauda Redis — JWT blacklist (${var.environment})"

  labels = var.labels
}
