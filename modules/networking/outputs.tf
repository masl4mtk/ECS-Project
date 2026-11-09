output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = [
    aws_subnet.public-subnet-A.id,
    aws_subnet.public-subnet-B.id
  ]
}

output "private_subnet_ids" {
  value = [
    aws_subnet.private-subnet-A.id,
    aws_subnet.private-subnet-B.id
  ]
}

output "alb_security_group_id" {
  value = aws_security_group.alb_sg.id
}

output "frontend_api_security_group_id" {
  value = aws_security_group.frontend_api_sg.id
}

output "worker_security_group_id" {
  value = aws_security_group.worker_sg.id
}