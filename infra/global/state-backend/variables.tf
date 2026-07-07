variable "aws_region" {
  description = "AWS region for the state backend"
  type        = string
  default     = "us-east-1"
}

variable "state_bucket_name" {
  description = "S3 bucket name for Terraform state — must be globally unique (e.g. sauda-terraform-state-<YOUR_ACCOUNT_ID>)"
  type        = string
}

variable "lock_table_name" {
  description = "DynamoDB table name for state locking"
  type        = string
  default     = "sauda-terraform-state-lock"
}
