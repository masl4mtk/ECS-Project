resource "aws_ecr_repository" "app_repos" {
    for_each = toset(["frontend", "worker", "api"])
    name     = orderflow-${each.key}-repo
    image_tag_mutability = "MUTABLE"
    image_scanning_configuration {
        scan_on_push = true
    }
}