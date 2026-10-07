resource "aws_iam_role" "imagebuilder_instance" {
  name = "ImageBuilderInstanceRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "EC2ImageBuilderInstanceRole"
  }
}

resource "aws_iam_role_policy_attachment" "imagebuilder_instance" {
  role       = aws_iam_role.imagebuilder_instance.name
  policy_arn = "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilder"
}

resource "aws_iam_role_policy_attachment" "ssm_managed_instance" {
  role       = aws_iam_role.imagebuilder_instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "imagebuilder" {
  name = "EC2ImageBuilderInstanceProfile"
  role = aws_iam_role.imagebuilder_instance.name

  tags = {
    Name = "ImageBuilderInstaceProfile"
  }
}

resource "aws_iam_role_policy" "imagebuilder_s3" {
  name = "ImageBuilderS3LogUpload"
  role = aws_iam_role.imagebuilder_instance.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "ImageBuilderS3Access"
        Effect = "Allow"

        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:GetBucketLocation"
        ]

        Resource = [
          var.bucket_arn,
          "${var.bucket_arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role" "imagebuilder_execution" {
  name = "EC2ImageBuilderExecutionRole"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "imagebuilder.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "ImageBuilderExecutionRole"
  }
}

resource "aws_iam_role_policy_attachment" "imagebuilder_execution" {
  role       = aws_iam_role.imagebuilder_execution.name
  policy_arn = "arn:aws:iam::aws:policy/EC2ImageBuilderFullAccess"
}

resource "aws_iam_role_policy_attachment" "imagebuilder_execution_policy" {
  role       = aws_iam_role.imagebuilder_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/EC2ImageBuilderExecutionPolicy"
}

resource "aws_iam_role_policy" "image_ssm" {
  name = "GoldenAMIParameterUpdate"
  role = aws_iam_role.imagebuilder_execution.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Sid    = "UpdateGoldenAMIParameter"
        Effect = "Allow"

        Action = [
          "ssm:PutParameter"
        ]
        Resource = "arn:aws:ssm:${var.aws_region}:${var.account_id}:parameter/golden-ami/al2023/latest"
      }
    ]
  })
}

resource "aws_ssm_parameter" "golden_ami" {
  name        = "/golden-ami/al2023/latest"
  description = "The latest Golden AMI for Amazon Linux 2023"
  type        = "String"
  tier        = "Standard"
  data_type   = "aws:ec2:image"
  value       = "ami-0000000000000000" # Placeholder value, will be updated by Image Builder

  tags = {
    Name = "GoldenAMIParameter"
  }

  lifecycle {
    ignore_changes = [value]
  }
}
