moved {
  from = aws_vpc.golden-ami-vpc
  to   = module.network.aws_vpc.golden-ami-vpc
}

moved {
  from = aws_subnet.private
  to   = module.network.aws_subnet.private
}

moved {
  from = aws_subnet.public
  to   = module.network.aws_subnet.public
}

moved {
  from = aws_internet_gateway.golden-ami-igw
  to   = module.network.aws_internet_gateway.golden-ami-igw
}

moved {
  from = aws_route_table.public
  to   = module.network.aws_route_table.public
}

moved {
  from = aws_route_table_association.public
  to   = module.network.aws_route_table_association.public
}

moved {
  from = aws_route_table.private
  to   = module.network.aws_route_table.private
}

moved {
  from = aws_route_table_association.private
  to   = module.network.aws_route_table_association.private
}

moved {
  from = aws_security_group.golden-sg
  to   = module.network.aws_security_group.golden-sg
}

moved {
  from = aws_vpc_endpoint.s3
  to   = module.network.aws_vpc_endpoint.s3
}

moved {
  from = aws_vpc_endpoint.ssm
  to   = module.network.aws_vpc_endpoint.ssm
}

moved {
  from = aws_vpc_endpoint.ssmmessages
  to   = module.network.aws_vpc_endpoint.ssmmessages
}

moved {
  from = aws_vpc_endpoint.imagebuilder
  to   = module.network.aws_vpc_endpoint.imagebuilder
}

moved {
  from = aws_s3_bucket_ownership_controls.golden-ami
  to   = module.storage.aws_s3_bucket_ownership_controls.golden-ami
}

moved {
  from = aws_s3_bucket_public_access_block.golden-ami
  to   = module.storage.aws_s3_bucket_public_access_block.golden-ami
}

moved {
  from = aws_iam_role.imagebuilder_instance
  to   = module.iam.aws_iam_role.imagebuilder_instance
}

moved {
  from = aws_iam_role_policy_attachment.imagebuilder_instance
  to   = module.iam.aws_iam_role_policy_attachment.imagebuilder_instance
}

moved {
  from = aws_iam_role_policy_attachment.ssm_managed_instance
  to   = module.iam.aws_iam_role_policy_attachment.ssm_managed_instance
}

moved {
  from = aws_iam_instance_profile.imagebuilder
  to   = module.iam.aws_iam_instance_profile.imagebuilder
}

moved {
  from = aws_iam_role_policy.imagebuilder_s3
  to   = module.iam.aws_iam_role_policy.imagebuilder_s3
}

moved {
  from = aws_iam_role.imagebuilder_execution
  to   = module.iam.aws_iam_role.imagebuilder_execution
}

moved {
  from = aws_iam_role_policy_attachment.imagebuilder_execution
  to   = module.iam.aws_iam_role_policy_attachment.imagebuilder_execution
}

moved {
  from = aws_iam_role_policy.image_ssm
  to   = module.iam.aws_iam_role_policy.image_ssm
}

moved {
  from = aws_ssm_parameter.golden_ami
  to   = module.iam.aws_ssm_parameter.golden_ami
}

moved {
  from = aws_imagebuilder_component.security_patching
  to   = module.imagebuilder.aws_imagebuilder_component.security_patching
}

moved {
  from = aws_imagebuilder_component.cis_level1_hardening
  to   = module.imagebuilder.aws_imagebuilder_component.cis_level1_hardening
}

moved {
  from = aws_imagebuilder_component.baseline_agents
  to   = module.imagebuilder.aws_imagebuilder_component.baseline_agents
}

moved {
  from = aws_imagebuilder_component.trivy_install
  to   = module.imagebuilder.aws_imagebuilder_component.trivy_install
}

moved {
  from = aws_imagebuilder_component.vulnerability_scanning
  to   = module.imagebuilder.aws_imagebuilder_component.vulnerability_scanning
}

moved {
  from = aws_imagebuilder_image_recipe.golden_al2023
  to   = module.imagebuilder.aws_imagebuilder_image_recipe.golden_al2023
}

moved {
  from = aws_imagebuilder_infrastructure_configuration.golden_ami
  to   = module.imagebuilder.aws_imagebuilder_infrastructure_configuration.golden_ami
}

moved {
  from = aws_imagebuilder_distribution_configuration.golden_ami
  to   = module.imagebuilder.aws_imagebuilder_distribution_configuration.golden_ami
}

moved {
  from = aws_imagebuilder_image_pipeline.golden_ami
  to   = module.imagebuilder.aws_imagebuilder_image_pipeline.golden_ami
}

moved {
  from = aws_imagebuilder_image.golden_ami
  to   = module.imagebuilder.aws_imagebuilder_image.golden_ami
}
