resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  tags = {
    Name = "ecs-project-vpc"
  }
}

########################################
## Subnets
########################################

resource "aws_subnet" "public-subnet-A" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "ecs-project-public-subnet-A"
  }
}

resource "aws_subnet" "public-subnet-B" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
  tags = {
    Name = "ecs-project-public-subnet-B"
  }
}

resource "aws_subnet" "private-subnet-A" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
    tags = {
    Name = "ecs-project-private-subnet-A"
    }
}

resource "aws_subnet" "private-subnet-B" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
    tags = {
    Name = "ecs-project-private-subnet-B"
    }
}

########################################
## Internet Gateway
########################################

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "ecs-project-igw"
  }
}

########################################
## NAT Gateway
########################################

resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "ecs-project-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public-subnet-A.id
  depends_on    = [aws_internet_gateway.main]
  tags = {
    Name = "ecs-project-nat-gateway"
  }
}

#########################################
## Route Tables & Associations
#########################################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
  tags = {
    Name = "ecs-project-public-route-table"
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
  tags = {
    Name = "ecs-project-private-route-table"
  }
}

resource "aws_route_table_association" "public-subnet-A" {
  subnet_id      = aws_subnet.public-subnet-A.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "public-subnet-B" {
  subnet_id      = aws_subnet.public-subnet-B.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private-subnet-A" {
  subnet_id      = aws_subnet.private-subnet-A.id
  route_table_id = aws_route_table.private.id
}

resource "aws_route_table_association" "private-subnet-B" {
  subnet_id      = aws_subnet.private-subnet-B.id
  route_table_id = aws_route_table.private.id
}

##########################################
## Security Groups
##########################################

resource "aws_security_group" "alb_sg" {
  name        = "alb-sg"
  description = "Security group for ALB"
  vpc_id      = aws_vpc.main.id
  tags = {
    Name = "ecs-project-alb-sg"
  }

    ingress {
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    ingress {
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
}
resource "aws_security_group" "frontend_api_sg" {
    name        = "frontend-api-sg"
    description = "Security group for frontend and API tasks"
    vpc_id      = aws_vpc.main.id
    tags = {
        Name = "ecs-project-frontend-api-sg"
    }

    ingress {
        from_port = 8080
        to_port   = 8080
        protocol  = "tcp"
        security_groups = [aws_security_group.alb_sg.id]
    }

    ingress {
        from_port = 3000
        to_port   = 3000
        protocol  = "tcp"
        security_groups = [aws_security_group.alb_sg.id]
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "worker_sg" {
    name        = "worker-sg"
    description = "Security group for worker tasks"
    vpc_id      = aws_vpc.main.id
    tags = {
        Name = "ecs-project-worker-sg"
    }

    egress {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_security_group" "db_sg" {
    name        = "db-sg"
    description = "Security group for database"
    vpc_id      = aws_vpc.main.id
    tags = {
        Name = "ecs-project-db-sg"
    }

    ingress {
        from_port       = 5432
        to_port         = 5432
        protocol        = "tcp"
        security_groups = [aws_security_group.worker_sg.id]
    }

    ingress {
        from_port       = 5432
        to_port         = 5432
        protocol        = "tcp"
        security_groups = [aws_security_group.frontend_api_sg.id]
    }
}

resource "aws_db_subnet_group" "main" {
    name       = "ecs-project-db-subnet-group"
    description = "Subnet group for RDS database"
    subnet_ids = [aws_subnet.private-subnet-A.id, aws_subnet.private-subnet-B.id]
    tags = {
        Name = "ecs-project-db-subnet-group"
    }
}
