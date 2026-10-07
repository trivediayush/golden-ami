output "launch_template_id" {
  description = "ID of the Golden AMI launch template."
  value       = aws_launch_template.golden_ami.id
}

output "autoscaling_group_name" {
  description = "Name of the Golden AMI Auto Scaling group."
  value       = aws_autoscaling_group.golden_ami.name
}

output "refresh_lambda_name" {
  description = "Name of the Lambda that refreshes the Auto Scaling group."
  value       = aws_lambda_function.asg_refresh.function_name
}

output "cleanup_lambda_name" {
  description = "Name of the report-only Golden AMI cleanup Lambda."
  value       = aws_lambda_function.cleanup.function_name
}
