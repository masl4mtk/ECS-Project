resource "aws_ecr_repository" "api" {
    name                 = "api"
    image_tag_mutability = "MUTABLE"
    image_scanning_configuration {
        scan_on_push = true
    }
    tags = {
        Name = "api"
    }
}

resource "aws_ecr_repository" "worker" {
    name                 = "worker"
    image_tag_mutability = "MUTABLE"
    image_scanning_configuration {
        scan_on_push = true
    }
    tags = {
        Name = "worker"
    }
}

resource "aws_ecr_repository" "frontend" {
    name                 = "frontend"
    image_tag_mutability = "MUTABLE"
    image_scanning_configuration {
        scan_on_push = true
    }
    tags = {
        Name = "frontend"
    }
}