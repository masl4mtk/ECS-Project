provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "state" {
  bucket = "masl4mtk-ecs-project-state-file"
}