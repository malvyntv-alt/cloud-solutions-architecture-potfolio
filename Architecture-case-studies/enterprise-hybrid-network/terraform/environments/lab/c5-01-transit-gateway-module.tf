# Transit gateway module. See docs/terraform-resource-map.md for the full resource index.

module "transit_gateway" {
  source = "../../modules/transit-gateway"
  name   = var.project_name
  networks = { for key, cidr in local.networks : key => {
    cidr       = cidr
    vpc_id     = module.vpc[key].vpc_id
    subnet_ids = module.vpc[key].attachment_subnet_ids
  } }
  allowed_routes = local.allowed_routes
}
