provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "state" {
  bucket = "masl4mtk-ecs-project-state-file"
}

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

data "aws_iam_policy_document" "github_trust" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:masl4mtk@283199617/ECS-Project@1446870598:*"]
    }
  }
}


resource "aws_iam_role" "github_actions" {
  name               = "github-actions-orderflow"
  assume_role_policy = data.aws_iam_policy_document.github_trust.json
}

data "aws_iam_policy_document" "github_permissions" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:*",
      "ecs:*",
      "ec2:*",
      "elasticloadbalancing:*",
      "rds:*",
      "sqs:*",
      "secretsmanager:*",
      "logs:*",
      "acm:*",
      "route53:*",
      "s3:*",
      "iam:*",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_role_policy" "github_actions" {
  name   = "github-actions-orderflow-permissions"
  role   = aws_iam_role.github_actions.id
  policy = data.aws_iam_policy_document.github_permissions.json
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}
