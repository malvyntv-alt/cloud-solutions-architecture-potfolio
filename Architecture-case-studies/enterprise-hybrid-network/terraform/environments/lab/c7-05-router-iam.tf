# Router iam. See docs/terraform-resource-map.md for the full resource index.

resource "aws_iam_role" "router" {
  for_each           = local.hybrid
  name_prefix        = "hybrid-router-"
  assume_role_policy = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Principal = { Service = "ec2.amazonaws.com" }, Action = "sts:AssumeRole" }] })
}

resource "aws_iam_role_policy_attachment" "router_ssm" {
  for_each   = local.hybrid
  role       = aws_iam_role.router[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy" "router_vpn" {
  for_each = local.hybrid
  role     = aws_iam_role.router[each.key].id
  # DescribeVpnConnections does not support resource-level IAM permissions.
  policy = jsonencode({ Version = "2012-10-17", Statement = [{ Effect = "Allow", Action = "ec2:DescribeVpnConnections", Resource = "*" }] })
}

resource "aws_iam_instance_profile" "router" {
  for_each = local.hybrid
  role     = aws_iam_role.router[each.key].name
}
