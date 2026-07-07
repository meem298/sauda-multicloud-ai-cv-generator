output "state_bucket_name" {
  description = "S3 bucket name — use this in backend.tf of each environment"
  value       = aws_s3_bucket.terraform_state.bucket
}

output "state_bucket_arn" {
  value = aws_s3_bucket.terraform_state.arn
}

output "lock_table_name" {
  description = "DynamoDB table name — use this in backend.tf of each environment"
  value       = aws_dynamodb_table.terraform_state_lock.name
}
