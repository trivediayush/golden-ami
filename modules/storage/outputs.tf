output "bucket_name" {
  description = "Name of the private Image Builder S3 bucket."
  value       = aws_s3_bucket.golden-ami.bucket
}

output "bucket_arn" {
  description = "ARN of the Image Builder S3 bucket."
  value       = aws_s3_bucket.golden-ami.arn
}
