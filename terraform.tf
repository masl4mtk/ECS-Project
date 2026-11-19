terraform {
  required_version = ">= 1.10.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket       = "masl4mtk-ecs-project-state-file"
    key          = "statefile"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}

provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "orderflow"
      Environment = "production"
      Owner       = "Maslamah"
      ManagedBy   = "terraform"
    }
  }
}
