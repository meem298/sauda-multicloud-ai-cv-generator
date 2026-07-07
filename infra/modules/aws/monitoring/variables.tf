variable "project" {
  type    = string
  default = "sauda"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "log_retention_days" {
  type    = number
  default = 7
}

variable "ecs_cluster_name" {
  type = string
}

variable "ecs_service_name" {
  type = string
}

variable "alb_arn_suffix" {
  type = string
}

variable "alarm_actions" {
  description = "List of ARNs to notify on alarm (e.g. SNS topic)"
  type        = list(string)
  default     = []
}

variable "target_group_arn_suffix" {
  description = "ALB target group ARN suffix for response-time alarm dimension"
  type        = string
  default     = ""
}

variable "tags" {
  type    = map(string)
  default = {}
}
