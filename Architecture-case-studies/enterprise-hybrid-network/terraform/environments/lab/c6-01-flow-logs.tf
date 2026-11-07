# Flow logs. See docs/terraform-resource-map.md for the full resource index.

resource "aws_cloudwatch_log_group" "flow" {
  name              = "/aws/vpc/${var.project_name}/flow"
  retention_in_days = 7
}

resource "aws_flow_log" "vpc" {
  for_each                 = local.networks
  vpc_id                   = module.vpc[each.key].vpc_id
  traffic_type             = "ALL"
  iam_role_arn             = aws_iam_role.flow.arn
  log_destination          = aws_cloudwatch_log_group.flow.arn
  max_aggregation_interval = 60
  depends_on               = [aws_iam_role_policy.flow]
}
