variable "project" {
  type    = string
  default = "sauda"
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "sg_redis_id" {
  type = string
}

variable "max_data_storage_gb" {
  type    = number
  default = 1
}

variable "max_ecpu_per_second" {
  type    = number
  default = 1000
}

variable "tags" {
  type    = map(string)
  default = {}
}
