# Root composition for the Golden AMI infrastructure.

data "aws_caller_identity" "current" {}

module "network" {
  source     = "./modules/network"
  aws_region = var.aws_region
}

module "storage" {
  source     = "./modules/storage"
  account_id = data.aws_caller_identity.current.account_id
}

module "iam" {
  source     = "./modules/iam"
  aws_region = var.aws_region
  account_id = data.aws_caller_identity.current.account_id
  bucket_arn = module.storage.bucket_arn
}

module "imagebuilder" {
  source                = "./modules/imagebuilder"
  aws_region            = var.aws_region
  account_id            = data.aws_caller_identity.current.account_id
  subnet_id             = module.network.private_subnet_id
  security_group_id     = module.network.security_group_id
  bucket_name           = module.storage.bucket_name
  instance_profile_name = module.iam.instance_profile_name
  ssm_parameter_name    = module.iam.ssm_parameter_name
}

module "autoscaling" {
  source             = "./modules/autoscaling"
  aws_region         = var.aws_region
  account_id         = data.aws_caller_identity.current.account_id
  public_subnet_id   = module.network.public_subnet_id
  security_group_id  = module.network.security_group_id
  ssm_parameter_name = module.iam.ssm_parameter_name
}
