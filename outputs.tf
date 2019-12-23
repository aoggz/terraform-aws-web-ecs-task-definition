

output "web_ecr_repository_url" {
  value       = aws_ecr_repository.web.repository_url
  description = "URL of ECR Repository for web Docker image"
}

output "ecs_task_definition_arn" {
  value       = aws_ecs_task_definition.app.arn
  description = "ARN of created ECS task definition"
}
