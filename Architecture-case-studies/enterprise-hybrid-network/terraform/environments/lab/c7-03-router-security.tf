# Router security. See docs/terraform-resource-map.md for the full resource index.

resource "aws_security_group" "router" {
  for_each    = local.hybrid
  name_prefix = "hybrid-router-"
  vpc_id      = aws_vpc.onprem[each.key].id
  # IKE peers are AWS-assigned after the customer gateway is created.
  # Host firewall narrows these ports to the two actual VPN peers.
  ingress {
    protocol    = "udp"
    from_port   = 500
    to_port     = 500
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol    = "udp"
    from_port   = 4500
    to_port     = 4500
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["172.16.1.0/24", "10.10.0.0/16", "10.30.0.0/16"]
  }
  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
