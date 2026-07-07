output "table_name" {
  value = aws_dynamodb_table.jwt_blacklist.name
}

output "table_arn" {
  value = aws_dynamodb_table.jwt_blacklist.arn
}

output "sessions_table_name" {
  value = aws_dynamodb_table.sessions.name
}

output "sessions_table_arn" {
  value = aws_dynamodb_table.sessions.arn
}
