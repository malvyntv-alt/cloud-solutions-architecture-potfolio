locals {
  zones = { for index, az in var.availability_zones : tostring(index) => az }
}
