# Firestore Native mode — replaces Memorystore Redis for JWT blacklist.
# Always Free: 1 GB storage, 50K reads/day, 20K writes/day — JWT blacklist
# uses < 1K operations/day so stays entirely within free tier.
resource "google_firestore_database" "jwt_blacklist" {
  project     = var.project_id
  name        = "jwt-blacklist-${var.environment}"
  location_id = var.location
  type        = "FIRESTORE_NATIVE"

  delete_protection_state = "DELETE_PROTECTION_DISABLED"
  deletion_policy         = "DELETE"
}

# TTL policy — auto-delete expired tokens (same behavior as Redis TTL).
resource "google_firestore_field" "ttl" {
  project    = var.project_id
  database   = google_firestore_database.jwt_blacklist.name
  collection = "blacklisted_tokens"
  field      = "expires_at"

  ttl_config {}
}
