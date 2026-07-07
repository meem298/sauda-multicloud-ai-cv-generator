output "database_name" {
  value = google_firestore_database.jwt_blacklist.name
}

output "database_id" {
  value = google_firestore_database.jwt_blacklist.id
}
