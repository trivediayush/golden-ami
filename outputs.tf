output "golden_ami_parameter" {
  description = "SSM parameter containing the latest Golden AMI."
  value       = module.iam.ssm_parameter_name
}

output "image_builder_pipeline" {
  description = "Golden AMI Image Builder pipeline."
  value       = module.imagebuilder.pipeline_name
}

output "golden_ami_launch_template_id" {
  description = "Golden AMI launch template ID."
  value       = module.autoscaling.launch_template_id
}

output "golden_ami_asg_name" {
  description = "Golden AMI Auto Scaling group."
  value       = module.autoscaling.autoscaling_group_name
}

output "asg_refresh_lambda" {
  description = "Golden AMI ASG rollout Lambda."
  value       = module.autoscaling.refresh_lambda_name
}

output "cleanup_lambda" {
  description = "Golden AMI cleanup/report Lambda."
  value       = module.autoscaling.cleanup_lambda_name
}

output "golden_ami_vpc_id" {
  description = "Golden AMI VPC ID."
  value       = module.network.vpc_id
}
