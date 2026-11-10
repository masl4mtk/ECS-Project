variable "db_subnet_group_name" {
  description = "The name of the DB subnet group to associate with this DB instance."
  type        = string
}

variable "db_security_group_id" {
  description = "The security group ID to associate with this DB instance."
  type        = string
}

