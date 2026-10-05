provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = "golden-ami"
      Environment = "shared"
      ManagedBy   = "terraform"
    }
  }
}
