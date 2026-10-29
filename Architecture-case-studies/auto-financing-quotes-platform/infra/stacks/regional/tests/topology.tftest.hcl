mock_provider "aws" {
  mock_data "aws_caller_identity" {
    defaults = { account_id = "123456789012" }
  }
  mock_data "aws_availability_zones" {
    defaults = { names = ["us-east-1a", "us-east-1b", "us-east-1c"] }
  }
  mock_resource "aws_rds_cluster" {
    defaults = {
      endpoint = "database.example.test"
      master_user_secret = [{
        secret_arn    = "arn:aws:secretsmanager:us-east-1:123456789012:secret:admin-example",
        secret_status = "active",
        kms_key_id    = "arn:aws:kms:us-east-1:123456789012:key/11111111-1111-1111-1111-111111111111"
      }]
    }
  }
  mock_resource "aws_acm_certificate" {
    defaults = {
      domain_validation_options = [{
        domain_name           = "quotes.example.com",
        resource_record_name  = "_verify.quotes.example.com",
        resource_record_type  = "CNAME",
        resource_record_value = "_verify.acm-validations.aws."
      }]
    }
  }
}
mock_provider "random" {}
variables {
  domain_name    = "quotes.example.com"
  hosted_zone_id = "Z123EXAMPLE"
  email_from     = "quotes@example.com"
}
run "demo_infrastructure_first" {
  command = plan
  variables { enable_runtime = false }
  assert {
    condition     = length(aws_rds_cluster_instance.main) == 1 && length(aws_nat_gateway.main) == 1
    error_message = "The demo should have one database instance and one NAT gateway."
  }
  assert {
    condition     = aws_ecs_service.web.desired_count == 0 && aws_ecs_service.publisher.desired_count == 0
    error_message = "Runtime must remain off before image push and migration."
  }
  assert {
    condition     = aws_rds_cluster.main.storage_encrypted && !aws_rds_cluster_instance.main[0].publicly_accessible
    error_message = "Database must be encrypted and private."
  }
}
run "ha_runtime_topology" {
  command = plan
  variables {
    profile        = "ha"
    enable_runtime = true
  }
  assert {
    condition     = length(aws_rds_cluster_instance.main) == 3 && length(aws_nat_gateway.main) == 3 && aws_ecs_service.web.desired_count == 3
    error_message = "HA profile requires three database instances, three NAT gateways, and three web tasks."
  }
  assert {
    condition     = aws_ecs_service.publisher.desired_count == 2 && aws_lambda_event_source_mapping.email[0].enabled
    error_message = "Active region requires redundant publishers and an enabled email consumer."
  }
}
run "standby_workers_are_disabled" {
  command = plan
  variables {
    enable_runtime  = true
    publish_enabled = false
  }
  assert {
    condition     = aws_ecs_service.publisher.desired_count == 0 && !aws_lambda_event_source_mapping.email[0].enabled
    error_message = "Recovery preparation must not publish or consume notifications."
  }
}

