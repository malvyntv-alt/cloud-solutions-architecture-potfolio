# Availability zones. See docs/terraform-resource-map.md for the full resource index.

data "aws_availability_zones" "available" { state = "available" }
