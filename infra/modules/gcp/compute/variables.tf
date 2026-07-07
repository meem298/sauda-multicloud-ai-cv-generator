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

variable "environment" {
  type    = string
  default = "dev"
}

variable "cloudrun_sa_email" {
  type = string
}

variable "jwt_secret_id" {
  type = string
}

variable "vertex_ai_key_secret_id" {
  type = string
}

variable "firestore_database_name" {
  type    = string
  default = "jwt-blacklist-dev"
}

variable "image_tag" {
  type    = string
  default = "latest"
}

variable "min_instances" {
  type    = number
  default = 0
}

variable "max_instances" {
  type    = number
  default = 5
}

variable "concurrency" {
  type    = number
  default = 80
}

variable "cpu" {
  type    = string
  default = "1"
}

variable "memory" {
  type    = string
  default = "512Mi"
}

variable "cpu_always_allocated" {
  description = "Keep CPU allocated between requests — false = scale to zero (dev), true = warm (prod)"
  type        = bool
  default     = false
}

variable "labels" {
  type    = map(string)
  default = {}
}
