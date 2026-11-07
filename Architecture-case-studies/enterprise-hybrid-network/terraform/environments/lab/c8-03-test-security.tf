# Test security. See docs/terraform-resource-map.md for the full resource index.

resource "aws_security_group" "test" {
  for_each    = local.test_networks
  name_prefix = "hybrid-test-${each.key}-"
  vpc_id      = module.vpc[each.key].vpc_id
  ingress {
    description = "Known TCP listener from approved peers and local positive controls"
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    cidr_blocks = concat([each.value], [for peer in local.allowed_destinations[each.key] : local.networks[peer]], var.enable_hybrid && contains(["production", "shared"], each.key) ? ["172.16.1.0/24"] : [])
  }
  egress {
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    cidr_blocks = concat(values(local.networks), ["172.16.1.0/24"])
  }
  egress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = [each.value]
  }
}

resource "aws_security_group" "ssm" {
  for_each    = local.test_networks
  name_prefix = "hybrid-ssm-"
  vpc_id      = module.vpc[each.key].vpc_id
  ingress {
    protocol        = "tcp"
    from_port       = 443
    to_port         = 443
    security_groups = [aws_security_group.test[each.key].id]
  }
}

resource "aws_security_group" "onprem_test" {
  for_each = local.onprem_tests
  vpc_id   = aws_vpc.onprem[each.key].id
  ingress {
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    cidr_blocks = ["10.10.0.0/16", "10.30.0.0/16"]
  }
  egress {
    protocol    = "tcp"
    from_port   = 8080
    to_port     = 8080
    cidr_blocks = ["10.10.0.0/16", "10.30.0.0/16"]
  }
  egress {
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
    cidr_blocks = ["172.16.0.0/16"]
  }
}

resource "aws_security_group" "onprem_ssm" {
  for_each = local.onprem_tests
  vpc_id   = aws_vpc.onprem[each.key].id
  ingress {
    protocol        = "tcp"
    from_port       = 443
    to_port         = 443
    security_groups = [aws_security_group.onprem_test[each.key].id, aws_security_group.router[each.key].id]
  }
}
