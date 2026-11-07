# Router instance. See docs/terraform-resource-map.md for the full resource index.

resource "aws_instance" "router" {
  for_each             = local.hybrid
  ami                  = data.aws_ami.ubuntu.id
  instance_type        = "t3.small"
  iam_instance_profile = aws_iam_instance_profile.router[each.key].name
  network_interface {
    network_interface_id = aws_network_interface.router[each.key].id
    device_index         = 0
  }
  metadata_options { http_tokens = "required" }
  root_block_device { encrypted = true }
  user_data = templatefile("${path.module}/templates/router.sh.tftpl", {
    dns_enabled    = var.enable_hybrid_dns
    onprem_test_ip = var.enable_hybrid_dns ? aws_instance.onprem_test["lab"].private_ip : ""
    region         = var.aws_region
    vpn_id         = aws_vpn_connection.onprem[each.key].id
    public_ip      = aws_eip.router[each.key].public_ip
  })
  user_data_replace_on_change = true
  depends_on                  = [aws_route_table_association.router, aws_iam_role_policy.router_vpn, aws_iam_role_policy_attachment.router_ssm]
  tags                        = { Name = "${var.project_name}-onprem-router" }
}
