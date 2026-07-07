# ── Artifact Registry ─────────────────────────────────────────────────────────
resource "google_artifact_registry_repository" "backend" {
  repository_id = "sauda-backend"
  format        = "DOCKER"
  location      = var.region
  project       = var.project_id
  description   = "Sauda backend container images"

  labels = var.labels
}

# ── Cloud Run Service ─────────────────────────────────────────────────────────
# Direct public HTTPS — no Load Balancer needed.
# Cloud Run provides a managed TLS certificate and stable HTTPS URL.
# Traffic: min_instances=0 in dev → scale to zero = $0 when idle.
resource "google_cloud_run_v2_service" "backend" {
  name     = "${var.project}-backend"
  location = var.region
  project  = var.project_id
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = var.cloudrun_sa_email

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    max_instance_request_concurrency = var.concurrency

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/sauda-backend/backend:${var.image_tag}"
      name  = "backend"

      ports {
        container_port = 3000
      }

      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
        cpu_idle = !var.cpu_always_allocated
      }

      env {
        name  = "NODE_ENV"
        value = var.environment
      }

      env {
        name  = "PORT"
        value = "3000"
      }

      env {
        name  = "GCP_PROJECT_ID"
        value = var.project_id
      }

      env {
        name  = "GCP_REGION"
        value = var.region
      }

      env {
        name  = "FIRESTORE_DATABASE"
        value = var.firestore_database_name
      }

      env {
        name = "JWT_SECRET"
        value_source {
          secret_key_ref {
            secret  = var.jwt_secret_id
            version = "latest"
          }
        }
      }

      env {
        name = "VERTEX_AI_KEY"
        value_source {
          secret_key_ref {
            secret  = var.vertex_ai_key_secret_id
            version = "latest"
          }
        }
      }

      liveness_probe {
        http_get {
          path = "/health"
          port = 3000
        }
        initial_delay_seconds = 15
        period_seconds        = 30
        failure_threshold     = 3
      }

      startup_probe {
        http_get {
          path = "/health"
          port = 3000
        }
        initial_delay_seconds = 5
        period_seconds        = 5
        failure_threshold     = 10
      }
    }
  }

  traffic {
    type    = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"
    percent = 100
  }

  labels = var.labels
}

# Allow public unauthenticated access to Cloud Run HTTPS endpoint.
resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.backend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}
