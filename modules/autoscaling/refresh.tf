data "archive_file" "asg_refresh_lambda" {
  type        = "zip"
  output_path = "${path.root}/.terraform/asg_refresh_lambda.zip"

  source {
    filename = "lambda_function.py"

    content = <<-PYTHON
      import boto3

      REGION = "${var.aws_region}"
      SSM_PARAMETER = "${var.ssm_parameter_name}"
      LAUNCH_TEMPLATE_ID = "${aws_launch_template.golden_ami.id}"
      ASG_NAME = "${aws_autoscaling_group.golden_ami.name}"

      ssm = boto3.client("ssm", region_name=REGION)
      ec2 = boto3.client("ec2", region_name=REGION)
      autoscaling = boto3.client("autoscaling", region_name=REGION)


      def lambda_handler(event, context):
          print("=== Golden AMI ASG Refresh ===")

          parameter = ssm.get_parameter(Name=SSM_PARAMETER)
          ami_id = parameter["Parameter"]["Value"]
          print(f"Latest Golden AMI: {ami_id}")

          template = ec2.describe_launch_template_versions(
              LaunchTemplateId=LAUNCH_TEMPLATE_ID,
              Versions=["$Default"]
          )
          current_version = template["LaunchTemplateVersions"][0]
          current_version_number = current_version["VersionNumber"]
          print(f"Current launch template version: {current_version_number}")

          new_version = ec2.create_launch_template_version(
              LaunchTemplateId=LAUNCH_TEMPLATE_ID,
              SourceVersion=str(current_version_number),
              VersionDescription=f"Golden AMI {ami_id}",
              LaunchTemplateData={
                  "ImageId": ami_id,
                  "InstanceType": "c7i-flex.large"
              }
          )
          new_version_number = (
              new_version["LaunchTemplateVersion"]["VersionNumber"]
          )
          print(f"New launch template version: {new_version_number}")

          autoscaling.update_auto_scaling_group(
              AutoScalingGroupName=ASG_NAME,
              LaunchTemplate={
                  "LaunchTemplateId": LAUNCH_TEMPLATE_ID,
                  "Version": str(new_version_number)
              }
          )

          refresh = autoscaling.start_instance_refresh(
              AutoScalingGroupName=ASG_NAME,
              Preferences={
                  "MinHealthyPercentage": 100,
                  "MaxHealthyPercentage": 110,
                  "InstanceWarmup": 300,
                  "SkipMatching": False
              }
          )
          refresh_id = refresh["InstanceRefreshId"]
          print(f"Instance refresh started: {refresh_id}")
          print("=== Golden AMI ASG Refresh Completed ===")

          return {
              "statusCode": 200,
              "ami_id": ami_id,
              "launch_template_version": new_version_number,
              "instance_refresh_id": refresh_id
          }
    PYTHON
  }
}

resource "aws_iam_role" "asg_refresh" {
  name = "golden-ami-asg-refresh"

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
    Name = "golden-ami-asg-refresh"
  }
}

resource "aws_iam_role_policy_attachment" "asg_refresh_logs" {
  role       = aws_iam_role.asg_refresh.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy" "asg_refresh" {
  name = "GoldenAMIAsgRefresh"
  role = aws_iam_role.asg_refresh.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadGoldenAMIParameter"
        Effect   = "Allow"
        Action   = ["ssm:GetParameter"]
        Resource = "arn:aws:ssm:${var.aws_region}:${var.account_id}:parameter${var.ssm_parameter_name}"
      },
      {
        Sid      = "ReadLaunchTemplateVersions"
        Effect   = "Allow"
        Action   = ["ec2:DescribeLaunchTemplateVersions"]
        Resource = "*"
      },
      {
        Sid      = "CreateLaunchTemplateVersion"
        Effect   = "Allow"
        Action   = ["ec2:CreateLaunchTemplateVersion"]
        Resource = aws_launch_template.golden_ami.arn
      },
      {
        Sid    = "UpdateAndRefreshAutoScalingGroup"
        Effect = "Allow"
        Action = [
          "autoscaling:UpdateAutoScalingGroup",
          "autoscaling:StartInstanceRefresh"
        ]
        Resource = aws_autoscaling_group.golden_ami.arn
      }
    ]
  })
}

resource "aws_lambda_function" "asg_refresh" {
  function_name = "golden-ami-asg-refresh"
  description   = "Roll out the latest Golden AMI through an ASG instance refresh"

  role    = aws_iam_role.asg_refresh.arn
  handler = "lambda_function.lambda_handler"
  runtime = "python3.13"

  filename         = data.archive_file.asg_refresh_lambda.output_path
  source_code_hash = data.archive_file.asg_refresh_lambda.output_base64sha256

  timeout     = 300
  memory_size = 128

  depends_on = [
    aws_iam_role_policy_attachment.asg_refresh_logs,
    aws_iam_role_policy.asg_refresh
  ]

  tags = {
    Name = "golden-ami-asg-refresh"
  }
}

resource "aws_cloudwatch_event_rule" "asg_refresh" {
  name                = "golden-ami-asg-refresh"
  description         = "Trigger Golden AMI ASG refresh weekly"
  schedule_expression = "cron(30 3 ? * MON *)"

  tags = {
    Name = "golden-ami-asg-refresh"
  }
}

resource "aws_cloudwatch_event_target" "asg_refresh" {
  rule = aws_cloudwatch_event_rule.asg_refresh.name
  arn  = aws_lambda_function.asg_refresh.arn
}

resource "aws_lambda_permission" "asg_refresh_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.asg_refresh.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.asg_refresh.arn
}
