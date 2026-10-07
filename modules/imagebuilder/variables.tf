variable "aws_region" {
  description = "AWS region in which to create Image Builder resources."
  type        = string
}

variable "account_id" {
  description = "AWS account ID used in the AMI distribution configuration."
  type        = string
}

variable "subnet_id" {
  description = "Private subnet in which Image Builder launches build instances."
  type        = string
}

variable "security_group_id" {
  description = "Security group attached to Image Builder build instances."
  type        = string
}

variable "bucket_name" {
  description = "S3 bucket used for build logs and the offline Trivy database."
  type        = string
}

variable "instance_profile_name" {
  description = "EC2 instance profile assumed by Image Builder build instances."
  type        = string
}

variable "ssm_parameter_name" {
  description = "Systems Manager parameter updated with the generated AMI."
  type        = string
}
