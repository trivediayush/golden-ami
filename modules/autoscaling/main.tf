resource "aws_launch_template" "golden_ami" {
  name        = "golden-ami-launch-template"
  description = "Launch template using the latest Golden AMI"

  image_id      = "resolve:ssm:${var.ssm_parameter_name}"
  instance_type = "c7i-flex.large"

  vpc_security_group_ids = [
    var.security_group_id
  ]

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 2
    instance_metadata_tags      = "enabled"
  }

  tag_specifications {
    resource_type = "instance"

    tags = {
      Name        = "golden-ami-instance"
      Project     = "golden-ami"
      Environment = "shared"
      ManagedBy   = "terraform"
    }
  }

  tags = {
    Name = "golden-ami-launch-template"
  }
}

resource "aws_autoscaling_group" "golden_ami" {
  name             = "golden-ami-asg"
  min_size         = 1
  max_size         = 1
  desired_capacity = 1

  vpc_zone_identifier = [
    var.public_subnet_id
  ]

  health_check_type         = "EC2"
  health_check_grace_period = 300

  launch_template {
    id      = aws_launch_template.golden_ami.id
    version = "$Latest"
  }

  instance_maintenance_policy {
    min_healthy_percentage = 100
    max_healthy_percentage = 110
  }

  tag {
    key                 = "Name"
    value               = "golden-ami-asg-instance"
    propagate_at_launch = true
  }

  tag {
    key                 = "Project"
    value               = "golden-ami"
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = "shared"
    propagate_at_launch = true
  }
}
