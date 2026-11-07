# Router interface. See docs/terraform-resource-map.md for the full resource index.

resource "aws_network_interface" "router" {
  for_each          = local.hybrid
  subnet_id         = aws_subnet.router[each.key].id
  private_ips       = ["172.16.0.10"]
  security_groups   = concat([aws_security_group.router[each.key].id], var.enable_hybrid_dns ? [aws_security_group.router_dns["lab"].id] : [])
  source_dest_check = false
}

resource "aws_eip" "router" {
  for_each          = local.hybrid
  domain            = "vpc"
  network_interface = aws_network_interface.router[each.key].id
  depends_on        = [aws_internet_gateway.onprem]
}
