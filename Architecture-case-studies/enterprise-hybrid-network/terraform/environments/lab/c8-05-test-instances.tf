# Test instances. See docs/terraform-resource-map.md for the full resource index.

resource "aws_instance" "test" {
  for_each                    = local.test_hosts
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = module.vpc[each.value.network].workload_subnet_ids[each.value.zone]
  vpc_security_group_ids      = [aws_security_group.test[each.value.network].id]
  iam_instance_profile        = aws_iam_instance_profile.test[0].name
  associate_public_ip_address = false
  metadata_options { http_tokens = "required" }
  root_block_device { encrypted = true }
  user_data                   = file("${path.module}/templates/test-host.sh")
  user_data_replace_on_change = true
  depends_on                  = [aws_vpc_endpoint.ssm, aws_iam_role_policy_attachment.test, aws_route53_resolver_endpoint.inbound, aws_route53_resolver_endpoint.outbound]
  tags                        = { Name = "${var.project_name}-test-${each.key}" }
}

resource "aws_instance" "onprem_test" {
  for_each                    = local.onprem_tests
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.onprem_workload[each.key].id
  vpc_security_group_ids      = concat([aws_security_group.onprem_test[each.key].id], var.enable_hybrid_dns ? [aws_security_group.onprem_dns_client["lab"].id] : [])
  iam_instance_profile        = aws_iam_instance_profile.test[0].name
  associate_public_ip_address = false
  metadata_options { http_tokens = "required" }
  root_block_device { encrypted = true }
  user_data                   = file("${path.module}/templates/test-host.sh")
  user_data_replace_on_change = true
  depends_on                  = [aws_vpc_endpoint.onprem_ssm, aws_iam_role_policy_attachment.test]
  tags                        = { Name = "${var.project_name}-onprem-test" }
}
