resource "aws_route53_zone" "cloud" {
  for_each = local.dns
  name     = "aws.lab.test"
  vpc { vpc_id = module.vpc["shared"].vpc_id }
}
resource "aws_route53_zone_association" "production" {
  for_each = local.dns
  zone_id  = aws_route53_zone.cloud[each.key].zone_id
  vpc_id   = module.vpc["production"].vpc_id
}
resource "aws_route53_record" "shared_test" {
  for_each = local.dns
  zone_id  = aws_route53_zone.cloud[each.key].zone_id
  name     = "shared.aws.lab.test"
  type     = "A"
  ttl      = 30
  records  = [aws_instance.test["shared-0"].private_ip]
}
resource "aws_route53_resolver_rule" "onprem" {
  for_each             = local.dns
  domain_name          = "onprem.lab.test"
  name                 = "${var.project_name}-onprem"
  rule_type            = "FORWARD"
  resolver_endpoint_id = aws_route53_resolver_endpoint.outbound[each.key].id
  target_ip {
    ip   = "172.16.0.10"
    port = 53
  }
}
resource "aws_route53_resolver_rule_association" "onprem" {
  for_each         = local.dns_vpcs
  resolver_rule_id = aws_route53_resolver_rule.onprem["lab"].id
  vpc_id           = module.vpc[each.key].vpc_id
}
output "hybrid_dns" {
  value = var.enable_hybrid_dns ? {
    inbound_ips      = ["10.30.1.10", "10.30.2.10"]
    onprem_dns_ip    = "172.16.0.10"
    cloud_test_name  = "shared.aws.lab.test"
    onprem_test_name = "host.onprem.lab.test"
  } : null
}
