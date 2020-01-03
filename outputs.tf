
output "cloudwatch_log_group_name" {
  value = aws_cloudwatch_log_group.main.name
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.web.repository_url
  description = "URL of ECR Repository for web Docker image"
}

output "task_definition_arn" {
  value       = aws_ecs_task_definition.app.arn
  description = "ARN of created ECS task definition"
}

output "task_iam_role_id" {
  value       = aws_iam_role.task.id
  description = "Id of IAM role that ECS task will assume"
}
