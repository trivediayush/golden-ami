variable "aws_region" {
  description = "AWS region used to scope the Systems Manager parameter policy."
  type        = string
}

variable "account_id" {
  description = "AWS account ID used to scope IAM resources."
  type        = string
}

variable "bucket_arn" {
  description = "ARN of the bucket used for Image Builder logs and artifacts."
  type        = string
}
