resource "random_password" "db_password" {
    length  = 16
    special = true
    override_special = "_%"
}

resource "aws_secretsmanager_secret" "db_secret" {
    name = "orderflow-db-secret"
    description = "Master password for the OrderFlow RDS PostgreSQL instance"
    recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "db_secret_value" {
    secret_id     = aws_secretsmanager_secret.db_secret.id
    secret_string = random_password.db_password.result
}

resource "aws_db_instance" "postgres" {
    allocated_storage    = 20
    engine               = "postgres"
    engine_version       = "15.14"
    instance_class       = "db.t3.micro"
    skip_final_snapshot   = true
    storage_encrypted     = true
    publicly_accessible   = false
    db_name              = "orderflow"
    username             = "orderflow_admin"
    password             = aws_secretsmanager_secret_version.db_secret_value.secret_string
    db_subnet_group_name = var.db_subnet_group_name
    vpc_security_group_ids = [var.db_security_group_id]
}