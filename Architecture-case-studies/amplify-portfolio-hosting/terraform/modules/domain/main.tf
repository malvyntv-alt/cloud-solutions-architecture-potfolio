resource "aws_amplify_domain_association" "this" {
  count                  = var.enabled ? 1 : 0
  app_id                 = var.app_id
  domain_name            = var.domain_name
  wait_for_verification  = false
  enable_auto_sub_domain = false
  sub_domain {
    branch_name = var.branch_name
    prefix      = ""
  }
  sub_domain {
    branch_name = var.branch_name
    prefix      = "www"
  }
  lifecycle {
    precondition {
      condition     = !var.manage_dns_records || var.hosted_zone_id != ""
      error_message = "Managed DNS requires an existing public hosted zone ID."
    }
  }
}
locals {
  dns_enabled       = var.enabled && var.manage_dns_records
  certificate_parts = var.enabled ? regexall("\\S+", aws_amplify_domain_association.this[0].certificate_verification_dns_record) : []
  apex_record       = var.enabled ? one([for sub in aws_amplify_domain_association.this[0].sub_domain : sub.dns_record if sub.prefix == ""]) : ""
  www_record        = var.enabled ? one([for sub in aws_amplify_domain_association.this[0].sub_domain : sub.dns_record if sub.prefix == "www"]) : ""
}
resource "aws_route53_record" "validation" {
  count           = local.dns_enabled ? 1 : 0
  zone_id         = var.hosted_zone_id
  name            = local.certificate_parts[0]
  type            = "CNAME"
  ttl             = 300
  records         = [local.certificate_parts[2]]
  allow_overwrite = false
}
resource "aws_route53_record" "apex" {
  count           = local.dns_enabled ? 1 : 0
  zone_id         = var.hosted_zone_id
  name            = var.domain_name
  type            = "A"
  allow_overwrite = false
  alias {
    name                   = reverse(regexall("\\S+", local.apex_record))[0]
    zone_id                = "Z2FDTNDATAQYW2"
    evaluate_target_health = false
  }
}
resource "aws_route53_record" "www" {
  count           = local.dns_enabled ? 1 : 0
  zone_id         = var.hosted_zone_id
  name            = "www.${var.domain_name}"
  type            = "CNAME"
  ttl             = 300
  records         = [reverse(regexall("\\S+", local.www_record))[0]]
  allow_overwrite = false
}
