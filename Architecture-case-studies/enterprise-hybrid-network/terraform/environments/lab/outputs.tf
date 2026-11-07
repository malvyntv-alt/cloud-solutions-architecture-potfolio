output "hybrid" {
  value = var.enable_hybrid ? { router_instance_id = aws_instance.router["lab"].id, vpn_id = aws_vpn_connection.onprem["lab"].id, onprem_test_subnet_id = aws_subnet.onprem_workload["lab"].id } : null
}

output "address_space" {
  value = { aws_vpcs = local.networks, on_premises = local.on_premises_cidr }
}

output "networks" {
  value = { for key, network in module.vpc : key => {
    vpc_id                   = network.vpc_id
    workload_subnet_ids      = network.workload_subnet_ids
    workload_route_table_ids = network.workload_route_table_ids
    attachment_subnet_ids    = network.attachment_subnet_ids
  } }
}

output "transit_gateway" {
  value = { id = module.transit_gateway.id, attachment_ids = module.transit_gateway.attachment_ids, route_table_ids = module.transit_gateway.route_table_ids }
}

output "flow_log_group" { value = aws_cloudwatch_log_group.flow.name }

output "allowed_routes" { value = local.allowed_routes }

output "test_hosts" {
  value = { for key, host in aws_instance.test : key => { instance_id = host.id, private_ip = host.private_ip } }
}

output "onprem_test_host" {
  value = { for key, host in aws_instance.onprem_test : key => { instance_id = host.id, private_ip = host.private_ip } }
}
