variable "project" { type = string }
variable "environment" { type = string }
variable "aws_region" { type = string }

variable "ecr_image_uri" {
  type        = string
  description = "Full ECR image URI including tag, e.g. 123456789.dkr.ecr.us-east-1.amazonaws.com/sauda-backend:latest"
}

variable "jwt_secret_arn" { type = string }
variable "vertex_ai_key_arn" { type = string }
variable "pdf_bucket_name" { type = string }
variable "dynamodb_table_name" { type = string }
variable "sessions_table_name" { type = string }

variable "lambda_memory_mb" {
  type    = number
  default = 512
}

variable "lambda_timeout_sec" {
  type    = number
  default = 30
}

variable "reserved_concurrency" {
  type    = number
  default = 10
}

variable "log_retention_days" {
  type    = number
  default = 7
}

variable "tags" {
  type    = map(string)
  default = {}
}
