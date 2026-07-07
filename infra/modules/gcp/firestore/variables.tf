variable "project_id" { type = string }
variable "environment" { type = string }

variable "location" {
  description = "Firestore multi-region location — nam5 (US) is Always Free"
  type        = string
  default     = "nam5"
}

variable "labels" {
  type    = map(string)
  default = {}
}
