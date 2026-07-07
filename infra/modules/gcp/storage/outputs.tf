output "frontend_bucket_name" {
  value = google_storage_bucket.frontend.name
}

output "frontend_bucket_url" {
  value = google_storage_bucket.frontend.url
}

output "pdfs_bucket_name" {
  value = google_storage_bucket.pdfs.name
}

output "pdfs_bucket_url" {
  value = google_storage_bucket.pdfs.url
}
