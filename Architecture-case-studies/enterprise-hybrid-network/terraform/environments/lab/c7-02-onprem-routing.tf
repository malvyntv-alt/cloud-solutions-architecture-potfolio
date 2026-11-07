# Onprem routing. See docs/terraform-resource-map.md for the full resource index.

resource "aws_route_table" "router" {
  for_each = local.hybrid
  vpc_id   = aws_vpc.onprem[each.key].id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.onprem[each.key].id
  }
}

resource "aws_route_table_association" "router" {
  for_each       = local.hybrid
  subnet_id      = aws_subnet.router[each.key].id
  route_table_id = aws_route_table.router[each.key].id
}

resource "aws_route_table" "onprem_workload" {
  for_each = local.hybrid
  vpc_id   = aws_vpc.onprem[each.key].id
}

resource "aws_route_table_association" "onprem_workload" {
  for_each       = local.hybrid
  subnet_id      = aws_subnet.onprem_workload[each.key].id
  route_table_id = aws_route_table.onprem_workload[each.key].id
}

resource "aws_route" "onprem_workload" {
  for_each               = local.hybrid_networks
  route_table_id         = aws_route_table.onprem_workload["lab"].id
  destination_cidr_block = each.value
  network_interface_id   = aws_network_interface.router["lab"].id
}
