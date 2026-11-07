# Vpc module. See docs/terraform-resource-map.md for the full resource index.

module "vpc" {
  for_each           = local.networks                    #creates one module instance for every key/value pair in the map.
  source             = "../../modules/vpc"               #we iterate over key/value pairs, and repeat the entire module,
  name               = "${var.project_name}-${each.key}" # each.key	"production"
  cidr               = each.value                        #each.value	"10.10.0.0/16"
  availability_zones = local.availability_zones
}
