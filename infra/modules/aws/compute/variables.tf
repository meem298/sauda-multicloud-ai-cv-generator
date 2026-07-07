variable "project" {
  type    = string
  default = "sauda"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "sg_alb_id" {
  type = string
}

variable "sg_ecs_id" {
  type = string
}

variable "ecs_task_role_arn" {
  type = string
}

variable "ecs_execution_role_arn" {
  type = string
}

variable "jwt_secret_arn" {
  type = string
}

variable "vertex_ai_key_arn" {
  type = string
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN for HTTPS listener — use placeholder if domain not configured yet"
  type        = string
  default     = "<ACM_CERTIFICATE_ARN>"
}

variable "task_cpu" {
  description = "ECS task CPU units (256=0.25vCPU, 512=0.5vCPU)"
  type        = number
  default     = 256
}

variable "task_memory" {
  description = "ECS task memory in MB"
  type        = number
  default     = 512
}

variable "desired_count" {
  type    = number
  default = 1
}

variable "min_capacity" {
  type    = number
  default = 1
}

variable "max_capacity" {
  type    = number
  default = 3
}

variable "image_tag" {
  type    = string
  default = "latest"
}

variable "log_retention_days" {
  type    = number
  default = 7
}

variable "enable_deletion_protection" {
  type    = bool
  default = false
}

variable "alb_logs_bucket" {
  description = "S3 bucket name for ALB access logs — leave empty to disable"
  type        = string
  default     = ""
}

variable "pdf_bucket_name" {
  description = "S3 bucket name for PDF storage"
  type        = string
}

variable "dynamodb_table_name" {
  description = "DynamoDB table name for application data"
  type        = string
}

variable "sessions_table_name" {
  description = "DynamoDB table name for session management"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
