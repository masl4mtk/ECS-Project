locals {

  services = toset(["frontend", "api", "worker"])

  environment = [
    { name = "DB_HOST", value = var.db_address },
    { name = "DB_NAME", value = var.db_name },
    { name = "DB_USER", value = var.db_username },
    { name = "DB_SSL", value = "true" },
    { name = "AWS_REGION", value = var.aws_region },
    { name = "SQS_QUEUE_URL", value = var.sqs_queue_url },
  ]

  secrets = [
    { name = "DB_PASSWORD", valueFrom = var.db_secret_arn },
  ]
}


resource "aws_ecs_cluster" "main" {
  name = "orderflow-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "orderflow" {
  for_each          = local.services
  name              = "/ecs/orderflow-${each.key}"
  retention_in_days = 7
}

#####################
### Task Definitions
#####################

resource "aws_ecs_task_definition" "frontend" {
  family                   = "orderflow-frontend"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.execution_role_arn

  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name      = "app"
      image     = "${var.ecr_repository_urls["frontend"]}:${var.image_tag}"
      cpu       = 256
      memory    = 512
      essential = true

      portMappings = [
        {
          containerPort = 8080
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.orderflow["frontend"].name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "app"
        }
      }
    }
  ])

  tags = {
    Name = "frontend-app"
  }
}


#####################
#####################
#####################


resource "aws_ecs_task_definition" "api" {
  family                   = "orderflow-api"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arns["api"]


  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name        = "app"
      image       = "${var.ecr_repository_urls["api"]}:${var.image_tag}"
      cpu         = 256
      memory      = 512
      essential   = true
      environment = local.environment
      secrets     = local.secrets

      portMappings = [
        {
          containerPort = 3000
          protocol      = "tcp"
        }
      ]

      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.orderflow["api"].name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "app"
        }
      }
    }
  ])

  tags = {
    Name = "api-app"
  }
}


#####################
#####################
#####################

resource "aws_ecs_task_definition" "worker" {
  family                   = "orderflow-worker"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = var.execution_role_arn
  task_role_arn            = var.task_role_arns["worker"]


  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "X86_64"
  }

  container_definitions = jsonencode([
    {
      name        = "app"
      image       = "${var.ecr_repository_urls["worker"]}:${var.image_tag}"
      cpu         = 256
      memory      = 512
      essential   = true
      environment = local.environment
      secrets     = local.secrets


      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = aws_cloudwatch_log_group.orderflow["worker"].name
          "awslogs-region"        = var.aws_region
          "awslogs-stream-prefix" = "app"
        }
      }
    }
  ])

  tags = {
    Name = "worker-app"
  }
}



#######################
### SERVICES
#######################

resource "aws_ecs_service" "frontend" {
  name                              = "orderflow-frontend"
  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition.frontend.arn
  desired_count                     = var.desired_count
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 60

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.frontend_api_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.frontend_target_group_arn
    container_name   = "app"
    container_port   = 8080
  }

}

resource "aws_ecs_service" "api" {
  name                              = "orderflow-api"
  cluster                           = aws_ecs_cluster.main.id
  task_definition                   = aws_ecs_task_definition.api.arn
  desired_count                     = var.desired_count
  launch_type                       = "FARGATE"
  health_check_grace_period_seconds = 60

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.frontend_api_sg_id]
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = var.api_target_group_arn
    container_name   = "app"
    container_port   = 3000
  }
}

resource "aws_ecs_service" "worker" {
  name            = "orderflow-worker"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.worker.arn
  desired_count   = var.worker_desired_count
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.worker_sg_id]
    assign_public_ip = false
  }
}