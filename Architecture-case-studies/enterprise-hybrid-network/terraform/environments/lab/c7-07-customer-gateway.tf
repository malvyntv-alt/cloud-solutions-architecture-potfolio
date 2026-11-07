# Customer gateway. See docs/terraform-resource-map.md for the full resource index.

resource "aws_customer_gateway" "onprem" {
  for_each   = local.hybrid
  bgp_asn    = 65010
  ip_address = aws_eip.router[each.key].public_ip
  type       = "ipsec.1"
  tags       = { Name = "${var.project_name}-simulated-dc" }
}
