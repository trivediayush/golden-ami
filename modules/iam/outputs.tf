output "instance_profile_name" {
  description = "Name of the EC2 instance profile used by Image Builder."
  value       = aws_iam_instance_profile.imagebuilder.name
}

output "ssm_parameter_name" {
  description = "Name of the parameter containing the latest Golden AMI ID."
  value       = aws_ssm_parameter.golden_ami.name
}
