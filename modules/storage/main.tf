resource "aws_s3_bucket" "golden-ami" {
  bucket        = "golden-ami-s3-bucket-${var.account_id}"
  force_destroy = true

  tags = {
    Name = "golden-ami-s3-bucket"
  }

}

resource "aws_s3_bucket_ownership_controls" "golden-ami" {
  bucket = aws_s3_bucket.golden-ami.id

  rule {
    object_ownership = "BucketOwnerEnforced"
  }
}

resource "aws_s3_bucket_public_access_block" "golden-ami" {
  bucket = aws_s3_bucket.golden-ami.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
