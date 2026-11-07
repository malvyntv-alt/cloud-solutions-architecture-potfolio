# Site to site vpn. See docs/terraform-resource-map.md for the full resource index.

resource "aws_vpn_connection" "onprem" {
  for_each                             = local.hybrid
  customer_gateway_id                  = aws_customer_gateway.onprem[each.key].id
  transit_gateway_id                   = module.transit_gateway.id
  type                                 = "ipsec.1"
  static_routes_only                   = false
  tunnel1_inside_cidr                  = "169.254.21.0/30"
  tunnel2_inside_cidr                  = "169.254.22.0/30"
  tunnel1_ike_versions                 = ["ikev2"]
  tunnel2_ike_versions                 = ["ikev2"]
  tunnel1_phase1_encryption_algorithms = ["AES256"]
  tunnel2_phase1_encryption_algorithms = ["AES256"]
  tunnel1_phase2_encryption_algorithms = ["AES256"]
  tunnel2_phase2_encryption_algorithms = ["AES256"]
  tunnel1_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase1_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel2_phase2_integrity_algorithms  = ["SHA2-256"]
  tunnel1_phase1_dh_group_numbers      = [14]
  tunnel2_phase1_dh_group_numbers      = [14]
  tunnel1_phase2_dh_group_numbers      = [14]
  tunnel2_phase2_dh_group_numbers      = [14]
  tags                                 = { Name = "${var.project_name}-bgp" }
}
