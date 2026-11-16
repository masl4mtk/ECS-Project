module "network" {
  source = "./modules/networking"
}

module "ecr" {
  source = "./modules/ECR"
}

module "rds" {
  source               = "./modules/RDS"
  db_subnet_group_name = module.network.db_subnet_group_name
  db_security_group_id = module.network.db_security_group_id
}

module "sqs" {
  source = "./modules/SQS"
}

module "iam" {
  source          = "./modules/IAM"
  sqs_queue_arn   = module.sqs.queue_arn
  ecs_secrets_arn = module.rds.db_secret_arn
}

module "alb" {
  source                = "./modules/load-balancer"
  alb_security_group_id = module.network.alb_security_group_id
  subnet_ids            = module.network.public_subnet_ids
  vpc_id                = module.network.vpc_id
  certificate_arn       = module.route53.certificate_arn
}

module "ecs" {
  source                    = "./modules/ECS"
  db_address                = module.rds.db_address
  db_name                   = module.rds.db_name
  db_secret_arn             = module.rds.db_secret_arn
  db_username               = module.rds.db_username
  sqs_queue_url             = module.sqs.queue_url
  private_subnet_ids        = module.network.private_subnet_ids
  frontend_api_sg_id        = module.network.frontend_api_security_group_id
  worker_sg_id              = module.network.worker_security_group_id
  api_target_group_arn      = module.alb.api_target_group_arn
  frontend_target_group_arn = module.alb.frontend_target_group_arn
  aws_region                = "us-east-1"
  image_tag                 = var.image_tag
  ecr_repository_urls       = module.ecr.ecr_repository_urls
  execution_role_arn        = module.iam.execution_role_arn
  task_role_arns = {
    "worker" = module.iam.ecs_task_role_worker_arn
    "api"    = module.iam.ecs_task_role_api_arn
  }
  depends_on = [module.alb]

}

module "route53" {
  source       = "./modules/Route53"
  domain_name  = var.domain_name
  alb_dns_name = module.alb.alb_dns_name
  alb_zone_id  = module.alb.zone_id
}
