resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "ecs-project-vpc"
  }
}

resource "aws_subnet" "public-subnet-A" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"
  tags = {
    Name = "ecs-project-public-subnet-A"
  }
}

resource "aws_subnet" "public-subnet-B" {
  count                   = 2
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1b"
  tags = {
    Name = "ecs-project-public-subnet-B"
  }
}

resource "aws_subnet" "private-subnet-A" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-1a"
    tags = {
    Name = "ecs-project-private-subnet-A"
    }
}

resource "aws_subnet" "private-subnet-B" {
  count             = 2
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.4.0/24"
  availability_zone = "us-east-1b"
    tags = {
    Name = "ecs-project-private-subnet-B"
    }
}

