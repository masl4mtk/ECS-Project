resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "ecs-project-vpc"
  }
}

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

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
  tags = {
    Name = "ecs-project-igw"
  }
}
resource "aws_eip" "nat" {
  vpc = true
  tags = {
    Name = "ecs-project-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public-subnet-A.id
  tags = {
    Name = "ecs-project-nat-gateway"
  }
}

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
