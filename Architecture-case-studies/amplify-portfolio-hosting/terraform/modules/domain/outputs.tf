output "certificate_dns_record" {
  value = try(aws_amplify_domain_association.this[0].certificate_verification_dns_record, null)
}
output "subdomain_dns_records" {
  value = try({ for sub in aws_amplify_domain_association.this[0].sub_domain : sub.prefix => sub.dns_record }, {})
}
output "managed_dns_record_count" {
  value = length(aws_route53_record.validation) + length(aws_route53_record.apex) + length(aws_route53_record.www)
}
