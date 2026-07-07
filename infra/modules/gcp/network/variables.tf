variable "project" {
  type    = string
  default = "sauda"
}

variable "project_id" {
  type = string
}

variable "region" {
  type    = string
  default = "us-central1"
}

variable "subnet_cidr" {
  type    = string
  default = "10.1.1.0/24"
}

variable "enable_cloud_nat" {
  description = "Enable Cloud NAT — only needed in prod if workloads need private egress"
  type        = bool
  default     = false
}

variable "labels" {
  type    = map(string)
  default = {}
}
