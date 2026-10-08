output "private_subnet_id" {
  description = "ID of the private subnet used by Image Builder."
  value       = aws_subnet.private.id
}

output "public_subnet_id" {
  description = "ID of the public subnet used by the Golden AMI Auto Scaling group."
  value       = aws_subnet.public.id
}

output "security_group_id" {
  description = "ID of the security group used by Image Builder."
  value       = aws_security_group.golden-sg.id
}

output "vpc_id" {
  description = "ID of the Golden AMI VPC."
  value       = aws_vpc.golden-ami-vpc.id
}
