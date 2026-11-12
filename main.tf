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
  source = "./modules/IAM"
  sqs_queue_arn = module.sqs.queue_arn
  ecs_secrets_arn = module.rds.db_secret_arn
}