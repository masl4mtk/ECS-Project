output "ecr_repository_url" {
  value = aws_ecr_repository.app_repos[*].repository_url
}