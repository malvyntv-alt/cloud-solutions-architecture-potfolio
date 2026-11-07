locals {
  hybrid          = var.enable_hybrid ? { lab = true } : {}
  hybrid_networks = var.enable_hybrid ? { production = local.networks.production, shared = local.networks.shared } : {}
}

locals {
  common_tags = {
    Project     = var.project_name
    Environment = "lab"
    Owner       = var.owner
    ManagedBy   = "Terraform"
  }

  networks = {
    production  = "10.10.0.0/16"
    development = "10.20.0.0/16"
    shared      = "10.30.0.0/16"
    restricted  = "10.40.0.0/16"
  }

  on_premises_cidr = "172.16.0.0/16"
}

locals {
  availability_zones = var.availability_zones == null ? slice(sort(data.aws_availability_zones.available.names), 0, 2) : var.availability_zones
  allowed_destinations = {
    production  = ["shared", "restricted"]
    development = ["shared"]
    shared      = ["production", "development"]
    restricted  = ["production"]
  }
  allowed_routes = merge([for source, destinations in local.allowed_destinations : {
    for destination in destinations : "${source}-${destination}" => { source = source, destination = destination }
  }]...)
  workload_routes = merge([for key, route in local.allowed_routes : {
    for index in range(2) : "${key}-${index}" => merge(route, { zone = tostring(index) })
  }]...)
}

locals {
  test_networks        = var.enable_test_hosts ? local.networks : {}
  test_hosts           = { for pair in setproduct(keys(local.test_networks), ["0", "1"]) : "${pair[0]}-${pair[1]}" => { network = pair[0], zone = pair[1] } }
  management_endpoints = { for pair in setproduct(keys(local.test_networks), ["ssm", "ssmmessages"]) : "${pair[0]}-${pair[1]}" => { network = pair[0], service = pair[1] } }
}

locals {
  onprem_tests = var.enable_hybrid && var.enable_test_hosts ? { lab = true } : {}
}
