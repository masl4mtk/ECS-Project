resource "aws_db_instance" "postgres" {
    llocated_storage    = 20
    engine               = "postgres"
    engine_version       = "13.4"
    instance_class       = "db.t3.micro"
    db_name               = "orderflow"
    username             = "admin"
    password             = "admin123"
    db_subnet_group_name = var.db_subnet_group_name
    vpc_security_group_ids = [var.db_security_group_id]
    

  