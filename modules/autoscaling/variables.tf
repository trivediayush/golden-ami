variable "aws_region" {
  description = "AWS region for the Auto Scaling and rollout resources."
  type        = string
}

variable "account_id" {
  description = "AWS account ID used to scope the Lambda permissions."
  type        = string
}

variable "public_subnet_id" {
  description = "Public subnet in which the Auto Scaling group launches instances."
  type        = string
}

variable "security_group_id" {
  description = "Security group attached to instances launched by the template."
  type        = string
}

variable "ssm_parameter_name" {
  description = "Systems Manager parameter containing the latest Golden AMI ID."
  type        = string
}
