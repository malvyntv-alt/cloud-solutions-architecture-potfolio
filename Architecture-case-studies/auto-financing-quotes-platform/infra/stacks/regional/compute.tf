resource "aws_ecs_cluster" "main" {
  name = var.project
  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

locals {
  common_environment = [
    { name = "PROJECT", value = var.project },
    { name = "APP_MODE", value = "aws" },
    { name = "AWS_REGION", value = var.region },
    { name = "DATABASE_HOST", value = aws_rds_cluster.main.endpoint },
    { name = "DATABASE_SECRET_ARN", value = aws_secretsmanager_secret.app.arn },
    { name = "QUEUE_URL", value = aws_sqs_queue.notifications.url },
    { name = "PUBLIC_ORIGIN", value = local.origin },
    { name = "PUBLISH_ENABLED", value = tostring(var.publish_enabled) },
    { name = "ALB_ARN", value = aws_lb.main.arn },
    { name = "COGNITO_CLIENT_ID", value = aws_cognito_user_pool_client.web.id },
    { name = "COGNITO_ISSUER", value = "https://cognito-idp.${var.region}.amazonaws.com/${aws_cognito_user_pool.main.id}" }
  ]
}

resource "aws_ecs_task_definition" "main" {
  for_each                 = toset(["web", "publisher", "migration"])
  family                   = "${var.project}-${each.key}"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task[each.key].arn
  runtime_platform {
    cpu_architecture        = "X86_64"
    operating_system_family = "LINUX"
  }
  container_definitions = jsonencode([{
    name      = each.key,
    image     = "${aws_ecr_repository.app.repository_url}:${var.image_tag}",
    essential = true,
    command   = each.key == "web" ? ["gunicorn", "--bind", "0.0.0.0:8080", "--workers", "2", "--threads", "4", "--timeout", "30", "--worker-tmp-dir", "/dev/shm", "app.server:application"] : ["python", "-m", each.key == "publisher" ? "app.publisher" : "app.migrate"],
    environment = concat([for item in local.common_environment : item if each.key != "migration" || item.name != "DATABASE_SECRET_ARN"], each.key == "migration" ? [
      { name = "DATABASE_SECRET_ARN", value = aws_rds_cluster.main.master_user_secret[0].secret_arn },
      { name = "APP_SECRET_ARN", value = aws_secretsmanager_secret.app.arn }
    ] : []),
    portMappings           = each.key == "web" ? [{ containerPort = 8080, protocol = "tcp" }] : [],
    readonlyRootFilesystem = true,
    logConfiguration = { logDriver = "awslogs", options = {
      "awslogs-group"         = aws_cloudwatch_log_group.app[each.key].name,
      "awslogs-region"        = var.region,
      "awslogs-stream-prefix" = each.key
      }
    }
  }])
}

resource "aws_ecs_service" "web" {
  name                               = "${var.project}-web"
  cluster                            = aws_ecs_cluster.main.id
  task_definition                    = aws_ecs_task_definition.main["web"].arn
  desired_count                      = local.web_count
  launch_type                        = "FARGATE"
  health_check_grace_period_seconds  = 60
  deployment_minimum_healthy_percent = 100
  deployment_maximum_percent         = 200
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  availability_zone_rebalancing = "ENABLED"
  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.compute.id]
    assign_public_ip = false
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.web.arn
    container_name   = "web"
    container_port   = 8080
  }
  depends_on = [aws_lb_listener.https, aws_iam_role_policy_attachment.execution]

}

resource "aws_ecs_service" "publisher" {
  name            = "${var.project}-publisher"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main["publisher"].arn
  desired_count   = local.publisher_count
  launch_type     = "FARGATE"
  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }
  network_configuration {
    subnets          = aws_subnet.private[*].id
    security_groups  = [aws_security_group.compute.id]
    assign_public_ip = false
  }
  depends_on = [aws_iam_role_policy_attachment.execution]
}

resource "aws_appautoscaling_target" "web" {
  count              = var.enable_runtime ? 1 : 0
  min_capacity       = local.web_count
  max_capacity       = var.profile == "ha" ? 12 : 3
  resource_id        = "service/${aws_ecs_cluster.main.name}/${aws_ecs_service.web.name}"
  scalable_dimension = "ecs:service:DesiredCount"
  service_namespace  = "ecs"
}

resource "aws_appautoscaling_policy" "web" {
  count              = var.enable_runtime ? 1 : 0
  name               = "${var.project}-cpu"
  policy_type        = "TargetTrackingScaling"
  resource_id        = aws_appautoscaling_target.web[0].resource_id
  scalable_dimension = aws_appautoscaling_target.web[0].scalable_dimension
  service_namespace  = aws_appautoscaling_target.web[0].service_namespace
  target_tracking_scaling_policy_configuration {
    target_value = 60
    predefined_metric_specification { predefined_metric_type = "ECSServiceAverageCPUUtilization" }
    scale_in_cooldown  = 120
    scale_out_cooldown = 30
  }
}
