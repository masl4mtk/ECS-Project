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
