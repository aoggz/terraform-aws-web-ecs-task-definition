data "aws_region" "current" {}

resource "aws_ecr_repository" "web" {
  name = "${var.resource_prefix}-${terraform.workspace}/web"

  image_scanning_configuration {
    scan_on_push = true
  }
}

resource "null_resource" "publish_web_docker_image" {
  provisioner "local-exec" {
    command = <<EOF
$(aws ecr get-login --no-include-email --region us-east-1) || aws ecr get-login-password | docker login --username AWS --password-stdin ${aws_ecr_repository.web.repository_url};
docker tag $LOCAL_TAG $TAG;
docker push $TAG
EOF


    environment = {
      TAG       = "${aws_ecr_repository.web.repository_url}:${var.web_version}"
      LOCAL_TAG = "${var.web_image}:${var.web_version}"
    }
  }

  triggers = {
    value = "${var.web_image}:${var.web_version}"
  }

  depends_on = [aws_ecr_repository.web]
}

resource "aws_ecs_task_definition" "app" {
  family                   = "${var.resource_prefix}-${terraform.workspace}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = var.xray_cpu + var.web_cpu + var.reverse_proxy_cpu
  memory                   = var.xray_memory + var.web_memory + var.reverse_proxy_memory
  container_definitions    = local.container_definitions
  execution_role_arn       = aws_iam_role.execution.arn
  task_role_arn            = aws_iam_role.task.arn
}

resource "aws_cloudwatch_log_group" "main" {
  name              = "${var.resource_prefix}-${terraform.workspace}"
  retention_in_days = var.log_retention_in_days
}

resource "aws_iam_role_policy" "task" {
  name   = "${var.resource_prefix}-${terraform.workspace}-task"
  role   = aws_iam_role.task.id
  policy = data.aws_iam_policy_document.task_permissions.json
}

resource "aws_iam_role" "task" {
  name               = "${var.resource_prefix}-${terraform.workspace}-task"
  assume_role_policy = data.aws_iam_policy_document.task_execution.json
}

data "aws_iam_policy_document" "task_permissions" {
  statement {
    effect = "Allow"

    resources = [
      aws_cloudwatch_log_group.main.arn,
    ]

    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }

  statement {
    effect = "Allow"

    resources = [
      "*",
    ]

    actions = [
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
    ]
  }
}

data "aws_iam_policy_document" "task_execution" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "execution" {
  name = replace(
    "${var.resource_prefix}-${terraform.workspace}-task-exec",
    "/(.{0,64})(.*)/",
    "$1",
  ) # 64 character max-length
  assume_role_policy = data.aws_iam_policy_document.task_execution.json
}

resource "aws_iam_role_policy" "task_execution" {
  name   = "${var.resource_prefix}-${terraform.workspace}-task-exec"
  role   = aws_iam_role.execution.id
  policy = data.aws_iam_policy_document.task_execution_permissions.json
}

data "aws_iam_policy_document" "task_execution_permissions" {
  statement {
    effect = "Allow"

    resources = [
      "*",
    ]

    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents",
    ]
  }
}
