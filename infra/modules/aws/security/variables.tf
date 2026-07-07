variable "project" {
  type    = string
  default = "sauda"
}

variable "aws_region" {
  type    = string
  default = "us-east-1"
}

variable "vpc_id" {
  description = "VPC ID — required for ALB and ECS security groups"
  type        = string
}

variable "tags" {
  type    = map(string)
  default = {}
}
