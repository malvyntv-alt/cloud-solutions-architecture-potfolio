variable "name" { type = string }

variable "networks" {
  type = map(object({
    cidr       = string
    vpc_id     = string
    subnet_ids = list(string)
  }))
}

variable "allowed_routes" {
  type = map(object({ source = string, destination = string }))
}
