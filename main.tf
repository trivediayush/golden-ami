# Golden AMI Terraform Configuration
#

## VPC - Configuration

resource "aws_vpc" "golden-ami-vpc" {
  cidr_block = "10.0.0.0/16"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name        = "golden-ami-vpc"
    Environment = "shared"
    ManagedBy   = "Terraform"
  }
}

resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.golden-ami-vpc
  cidr_block              = "10.0.0.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = false

  tags = {
    Name = "golden-ami-subnet-private-eu-west-2a"
  }
}

resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.golden-ami-vpc
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "golden-ami-subnet-public1-eu-west-2a"
  }
}

resource "aws_internet_gateway" "golden-ami-igw" {
  vpc_id = aws_vpc.golden-ami-vpc

  tags = {
    Name = "golden-ami-igw"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.golden-ami-vpc

  route = {
    cidr_block = "0.0.0.0"
    gateway_id = aws_internet_gateway.golden-ami-igw
  }

  tags = {
    Name = "golden-rt-public"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public
  route_table_id = aws_route_table.public
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.golden-ami-vpc

  tags = {
    Name = "golden-rt-private"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_route_table.private
  route_table_id = aws_route_table.private
}

resource "aws_security_group" "golden-sg" {
  name        = "golden-ami-sg"
  description = "The security group for golden ami"
  vpc_id      = aws_vpc.golden-ami-vpc

  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "golden-ami-sg"
  }
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.golden-ami-vpc.id
  service_name      = "com.amazonaws.us-east-2.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private.id
  ]

  tags = {
    Name = "golden-ami-s3"
  }
}

resource "aws_vpc_endpoint" "ssm" {
    vpc_id = aws_vpc.golden-ami-vpc.id
    service_name = "com.amazonaws.us-east-2.ssm"
    vpc_endpoint_type = "Interface"
    subnet_ids = [aws_subnet.private.id]
    security_group_ids = [aws_security_group.golden-sg.id]
    private_dns_enabled = true

    tags = {
        Name = "golden-ami-ssm"
    }
}

resource "aws_vpc_endpoint" "ssmmessages" {
    vpc_id = aws_vpc.golden-ami-vpc.id
    service_name = "com.amazonaws.us-east-2.ssmmessages"
    vpc_endpoint_type = "Interface"
    subnet_ids = [ aws_subnet.private.id ]
    security_group_ids = [ aws_security_group.golden-sg.id ]
    private_dns_enabled = true

    tags = {
        Name = "golden-ami-ssmmessages"
    }
}

resource "aws_vpc_endpoint" "imagebuilder" {
    vpc_id = aws_vpc.golden-ami-vpc.id
    service_name = "com.amazonaws.us-east-2.imagebuilder"
    vpc_endpoint_type = "Interface"
    subnet_ids = [ aws_subnet.private.id ]
    security_group_ids = [ aws_security_group.golden-sg.id ]
    private_dns_enabled = true

    tags = {
      Name = "golden-ami-builderimage"
    }
}

resource "aws_s3" "golden-ami" {
    bucket = "golden-ami-s3-bucket-$(data.aws_caller_identity.current_account_id)"

    force_destory = true

    tags = {
        Name = "golden-ami-s3-bucket"
    }

    data "aws_caller_identity current {}
} 