resource "aws_iam_role" "execution" {
  name_prefix = "${var.project}-execution-"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Effect = "Allow", Principal = { Service = "ecs-tasks.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy_attachment" "execution" {
  role       = aws_iam_role.execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "task" {
  for_each    = toset(["web", "publisher", "migration", "email"])
  name_prefix = "${var.project}-${each.key}-"
  assume_role_policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Effect = "Allow", Principal = { Service = each.key == "email" ? "lambda.amazonaws.com" : "ecs-tasks.amazonaws.com" }, Action = "sts:AssumeRole" }]
  })
}

resource "aws_iam_role_policy" "db_secret" {
  for_each = aws_iam_role.task
  role     = each.value.id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{ Effect = "Allow", Action = ["secretsmanager:GetSecretValue"],
    Resource = each.key == "migration" ? [aws_secretsmanager_secret.app.arn, aws_rds_cluster.main.master_user_secret[0].secret_arn] : [aws_secretsmanager_secret.app.arn] }]
  })
}

resource "aws_iam_role_policy" "publish" {
  role = aws_iam_role.task["publisher"].id
  policy = jsonencode({
    Version   = "2012-10-17",
    Statement = [{ Effect = "Allow", Action = ["sqs:SendMessage"], Resource = aws_sqs_queue.notifications.arn }]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_vpc" {
  role       = aws_iam_role.task["email"].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

resource "aws_iam_role_policy" "email" {
  role = aws_iam_role.task["email"].id
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      { Effect = "Allow", Action = ["sqs:ReceiveMessage", "sqs:DeleteMessage", "sqs:GetQueueAttributes"], Resource = aws_sqs_queue.notifications.arn },
      { Effect   = "Allow", Action = ["ses:SendEmail"],
        Resource = ["arn:aws:ses:${var.region}:${local.account_id}:identity/${var.email_from}", aws_ses_configuration_set.main.arn],
      Condition = { StringEquals = { "ses:FromAddress" = var.email_from } } }
    ]
  })
}
