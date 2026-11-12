output "ecr_repository_urls" {
  value = {
    for repo_name, repo in aws_ecr_repository.app_repos : repo_name => repo.repository_url
  }
}