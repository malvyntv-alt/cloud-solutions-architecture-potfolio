mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = { account_id = "123456789012" }
  }
  mock_data "aws_partition" {
    defaults = { partition = "aws", dns_suffix = "amazonaws.com" }
  }
  mock_resource "aws_amplify_app" {
    defaults = { id = "dexample123", default_domain = "dexample123.amplifyapp.com" }
  }
  mock_resource "aws_apigatewayv2_api" {
    defaults = {
      id            = "exampleapi"
      api_endpoint  = "https://exampleapi.execute-api.us-east-1.amazonaws.com"
      execution_arn = "arn:aws:execute-api:us-east-1:123456789012:exampleapi"
    }
  }
  mock_resource "aws_amplify_domain_association" {
    defaults = {
      certificate_verification_dns_record = "_verify.malvernvito.com CNAME _verify.acm-validations.aws."
      sub_domain = [
        { branch_name = "main", prefix = "", dns_record = " CNAME dexample.cloudfront.net", verified = false },
        { branch_name = "main", prefix = "www", dns_record = " CNAME dexample.cloudfront.net", verified = false }
      ]
    }
  }
}
variables { amplify_app_id = "dexample123" }
run "public_counter_without_dns_cutover" {
  command = plan
  assert {
    condition     = module.database.billing_mode == "PAY_PER_REQUEST" && module.database.deletion_protection
    error_message = "Counter should use on-demand capacity and protect production data."
  }
  assert {
    condition     = module.api.route_keys == toset(["GET /views", "POST /views"])
    error_message = "Expose only the read and increment routes."
  }
  assert {
    condition     = module.domain.managed_dns_record_count == 0 && !output.custom_domain_enabled
    error_message = "Initial plan must not change custom domain DNS."
  }
  assert {
    condition     = yamldecode(module.hosting.build_spec).applications[0].appRoot == module.hosting.app_root
    error_message = "Amplify build appRoot must match its monorepo environment setting."
  }
}
run "association_only_keeps_dns_ownership_separate" {
  command = plan
  variables { enable_custom_domain = true }
  assert {
    condition     = module.domain.managed_dns_record_count == 0
    error_message = "Domain association must not silently take ownership of Route 53 records."
  }
}
run "explicit_terraform_dns_ownership" {
  command = plan
  variables {
    enable_custom_domain = true
    manage_dns_records   = true
    hosted_zone_id       = "ZEXAMPLE123"
  }
  assert {
    condition     = module.domain.managed_dns_record_count == 3
    error_message = "Explicit DNS ownership should create certificate, apex and www records."
  }
}
run "github_connection_is_a_required_prerequisite" {
  command = plan
  variables { amplify_app_id = "" }
  expect_failures = [var.amplify_app_id]
}
