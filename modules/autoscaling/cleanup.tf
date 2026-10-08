resource "aws_iam_role" "cleanup" {
  name = "golden-ami-cleanup"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "golden-ami-cleanup"
  }
}

resource "aws_iam_role_policy_attachment" "cleanup_logs" {
  role       = aws_iam_role.cleanup.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "cleanup" {
  name = "GoldenAMICleanup"
  role = aws_iam_role.cleanup.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "InspectImages"
        Effect = "Allow"
        Action = [
          "ec2:DescribeImages",
          "ec2:DescribeSnapshots",
          "ec2:DescribeInstances",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeLaunchTemplateVersions",
          "ec2:DescribeAutoScalingGroups"
        ]
        Resource = "*"
      }
    ]
  })
}

data "archive_file" "cleanup_lambda" {
  type        = "zip"
  output_path = "${path.root}/.terraform/cleanup_lambda.zip"

  source {
    filename = "lambda_function.py"

    content = <<-PYTHON
      import boto3
      from datetime import datetime, timezone

      REGION = "${var.aws_region}"

      ec2 = boto3.client("ec2", region_name=REGION)


      def lambda_handler(event, context):
          print("=== Golden AMI Cleanup Report ===")

          images = ec2.describe_images(
              Owners=["self"],
              Filters=[
                  {
                      "Name": "tag:Project",
                      "Values": ["golden-ami"]
                  }
              ]
          )["Images"]

          now = datetime.now(timezone.utc)
          print(f"Golden AMIs found: {len(images)}")

          for image in sorted(images, key=lambda item: item.get("CreationDate", "")):
              image_id = image["ImageId"]
              creation_date = image.get("CreationDate", "unknown")
              age_days = "unknown"

              if creation_date != "unknown":
                  created = datetime.fromisoformat(
                      creation_date.replace("Z", "+00:00")
                  )
                  age_days = (now - created).days

              print(
                  f"AMI={image_id} "
                  f"CreationDate={creation_date} "
                  f"AgeDays={age_days}"
              )

          print("Report only: no AMIs or snapshots were deleted.")
          print("=== Golden AMI Cleanup Report Completed ===")

          return {
              "statusCode": 200,
              "golden_ami_count": len(images),
              "message": "Report generated. No resources deleted."
          }
    PYTHON
  }
}

resource "aws_lambda_function" "cleanup" {
  function_name = "golden-ami-cleanup"
  description   = "Report Golden AMI age and lifecycle candidates"

  role    = aws_iam_role.cleanup.arn
  handler = "lambda_function.lambda_handler"
  runtime = "python3.13"

  filename         = data.archive_file.cleanup_lambda.output_path
  source_code_hash = data.archive_file.cleanup_lambda.output_base64sha256

  timeout     = 60
  memory_size = 128

  depends_on = [
    aws_iam_role_policy_attachment.cleanup_logs,
    aws_iam_role_policy.cleanup
  ]

  tags = {
    Name = "golden-ami-cleanup"
  }
}

resource "aws_iam_role" "cleanup_scheduler" {
  name = "golden-ami-cleanup-scheduler"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "scheduler.amazonaws.com"
        }
        Action = "sts:AssumeRole"
        Condition = {
          StringEquals = {
            "aws:SourceAccount" = var.account_id
          }
          ArnLike = {
            "aws:SourceArn" = "arn:aws:scheduler:${var.aws_region}:${var.account_id}:schedule/default/golden-ami-cleanup-weekly"
          }
        }
      }
    ]
  })

  tags = {
    Name = "golden-ami-cleanup-scheduler"
  }
}

resource "aws_iam_role_policy" "cleanup_scheduler" {
  name = "InvokeGoldenAMICleanup"
  role = aws_iam_role.cleanup_scheduler.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["lambda:InvokeFunction"]
        Resource = aws_lambda_function.cleanup.arn
      }
    ]
  })
}

resource "aws_scheduler_schedule" "cleanup" {
  name                         = "golden-ami-cleanup-weekly"
  description                  = "Weekly report of Golden AMI lifecycle candidates"
  schedule_expression          = "cron(0 3 ? * MON *)"
  schedule_expression_timezone = "Asia/Calcutta"

  flexible_time_window {
    mode = "OFF"
  }

  target {
    arn      = aws_lambda_function.cleanup.arn
    role_arn = aws_iam_role.cleanup_scheduler.arn

    input = jsonencode({
      action = "report"
    })
  }

  state = "ENABLED"

  depends_on = [
    aws_iam_role_policy.cleanup_scheduler
  ]
}
