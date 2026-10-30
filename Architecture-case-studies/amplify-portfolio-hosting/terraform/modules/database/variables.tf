variable "name" {
  type = string
}

variable "deletion_protection" {
  type    = bool
  default = true
}

variable "point_in_time_recovery" {
  type    = bool
  default = false
}
