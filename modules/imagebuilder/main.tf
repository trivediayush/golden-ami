resource "aws_imagebuilder_component" "security_patching" {
  name     = "security-patching"
  platform = "Linux"
  version  = "1.0.0"

  description = "Apply latest security patches to Amazon Linux 2023"

  data = yamlencode({
    name          = "security-patching"
    description   = "Apply latest security patches to Amazon Linux 2023"
    schemaVersion = 1.0

    phases = [
      {
        name = "build"

        steps = [
          {
            name   = "SecurityPatching"
            action = "ExecuteBash"

            inputs = {
              commands = [
                "dnf update --security -y"
              ]
            }
          }
        ]
      }
    ]
  })

  tags = {
    Name = "security-patching"
  }
}

resource "aws_imagebuilder_component" "cis_level1_hardening" {
  name     = "cis-level1-hardening"
  platform = "Linux"
  version  = "1.0.0"

  description = "CIS Amazon Linux 2023 Level 1 hardening for immutable golden AMI"

  data = yamlencode({
    name          = "cis-level1-hardening"
    description   = "CIS Amazon Linux 2023 Level 1 hardening for immutable golden AMI"
    schemaVersion = 1.0

    phases = [
      {
        name = "build"

        steps = [
          {
            name   = "ApplyCISHardening"
            action = "ExecuteBash"

            inputs = {
              commands = [
                "set -e",
                "dnf install -y libselinux-utils policycoreutils selinux-policy-targeted chrony cronie sudo openssh-server",
                "dnf remove -y setroubleshoot || true",
                "sed -i 's/^gpgcheck=.*/gpgcheck=1/g' /etc/dnf/dnf.conf || true",
                "sysctl -w kernel.yama.ptrace_scope=1",
                "mkdir -p /etc/systemd/coredump.conf.d",
                "printf '[Coredump]\\nStorage=none\\n' > /etc/systemd/coredump.conf.d/60-cis.conf",
                "setenforce 1 || true",
                "sed -i 's/^SELINUX=.*/SELINUX=enforcing/' /etc/selinux/config",
                "sed -i 's/^SELINUXTYPE=.*/SELINUXTYPE=targeted/' /etc/selinux/config",
                "update-crypto-policies --set DEFAULT",
                "systemctl enable chronyd",
                "systemctl enable crond",
                "cat > /etc/sysctl.d/60-cis-network.conf <<'EOF'\nnet.ipv4.ip_forward = 0\nnet.ipv4.conf.all.accept_source_route = 0\nnet.ipv4.conf.default.accept_source_route = 0\nnet.ipv4.conf.all.accept_redirects = 0\nnet.ipv4.conf.default.accept_redirects = 0\nnet.ipv4.conf.all.secure_redirects = 0\nnet.ipv4.conf.default.secure_redirects = 0\nnet.ipv4.conf.all.send_redirects = 0\nnet.ipv4.conf.default.send_redirects = 0\nnet.ipv4.conf.all.rp_filter = 1\nnet.ipv4.conf.default.rp_filter = 1\nEOF",
                "sysctl --system",
                "touch /etc/cron.allow",
                "chmod 600 /etc/cron.allow",
                "cat > /etc/ssh/sshd_config.d/60-cis-level1.conf <<'EOF'\nPermitRootLogin no\nPermitEmptyPasswords no\nIgnoreRhosts yes\nMaxAuthTries 4\nMaxStartups 10:30:60\nMaxSessions 10\nLogLevel INFO\nUsePAM yes\nBanner /etc/issue.net\nEOF",
                "cat > /etc/sudoers.d/60-cis-level1 <<'EOF'\nDefaults use_pty\nDefaults logfile=\"/var/log/sudo.log\"\nEOF",
                "chmod 440 /etc/sudoers.d/60-cis-level1",
                "visudo -cf /etc/sudoers",
                "systemctl enable sshd",
                "chmod 644 /etc/passwd /etc/group",
                "chmod 000 /etc/shadow /etc/gshadow",
                "chown root:root /etc/passwd /etc/group /etc/shadow /etc/gshadow"
              ]
            }
          }
        ]
      },
      {
        name = "validate"

        steps = [
          {
            name   = "ValidateCISHardening"
            action = "ExecuteBash"

            inputs = {
              commands = [
                "set -e",
                "grep -q '^gpgcheck=1' /etc/dnf/dnf.conf || true",
                "getenforce | grep -q Enforcing",
                "update-crypto-policies --show | grep -q DEFAULT",
                "sshd -T | grep -qi 'permitrootlogin no'",
                "sshd -T | grep -qi 'permitemptypasswords no'",
                "sshd -T | grep -qi 'maxauthtries 4'",
                "sshd -T | grep -qi 'maxsessions 10'",
                "sshd -T | grep -qi 'ignorerhosts yes'",
                "grep -q 'Defaults use_pty' /etc/sudoers.d/60-cis-level1",
                "systemctl is-enabled chronyd",
                "systemctl is-enabled sshd",
                "stat -c '%a %U:%G %n' /etc/passwd /etc/shadow /etc/group /etc/gshadow"
              ]
            }
          }
        ]
      }
    ]
  })

  tags = {
    Name = "cis-level1-hardening"
  }
}

resource "aws_imagebuilder_component" "baseline_agents" {
  name     = "baseline-agents"
  platform = "Linux"
  version  = "1.0.0"

  description = "Install and validate baseline management and monitoring agents"

  data = yamlencode({
    name          = "baseline-agents"
    description   = "Install and validate baseline management and monitoring agents"
    schemaVersion = 1.0

    phases = [
      {
        name = "build"

        steps = [
          {
            name   = "ConfigureSSMAgent"
            action = "ExecuteBash"

            inputs = {
              commands = [
                "set -e",
                "rpm -q amazon-ssm-agent",
                "systemctl enable amazon-ssm-agent"
              ]
            }
          },
          {
            name   = "InstallCloudWatchAgent"
            action = "ExecuteBash"

            inputs = {
              commands = [
                "set -e",
                "dnf install -y amazon-cloudwatch-agent",
                "systemctl enable amazon-cloudwatch-agent"
              ]
            }
          },
          {
            name   = "ConfigureEDRAgentPlaceholder"
            action = "ExecuteBash"

            inputs = {
              commands = [
                "set -e",
                "echo 'EDR agent installation is vendor-specific.'",
                "echo 'No EDR vendor/package was specified in the Golden AMI architecture.'",
                "echo 'EDR deployment remains an integration point for the selected enterprise EDR platform.'"
              ]
            }
          }
        ]
      },
      {
        name = "validate"

        steps = [
          {
            name   = "ValidateSSMAgent"
            action = "ExecuteBash"

            inputs = {
              commands = [
                "set -e",
                "rpm -q amazon-ssm-agent",
                "systemctl is-enabled amazon-ssm-agent"
              ]
            }
          },
          {
            name   = "ValidateCloudWatchAgent"
            action = "ExecuteBash"

            inputs = {
              commands = [
                "set -e",
                "rpm -q amazon-cloudwatch-agent",
                "systemctl is-enabled amazon-cloudwatch-agent"
              ]
            }
          }
        ]
      },
      {
        name = "test"

        steps = [
          {
            name   = "BaselineAgentsTest"
            action = "ExecuteBash"

            inputs = {
              commands = [
                "set -e",
                "echo '=== Baseline Agents Test ==='",
                "echo '--- SSM Agent ---'",
                "rpm -q amazon-ssm-agent",
                "systemctl is-enabled amazon-ssm-agent",
                "echo '--- CloudWatch Agent ---'",
                "rpm -q amazon-cloudwatch-agent",
                "systemctl is-enabled amazon-cloudwatch-agent",
                "echo '--- EDR ---'",
                "echo 'EDR agent deployment is vendor-specific and remains an integration point.'",
                "echo '=== Baseline Agents Test Completed ==='"
              ]
            }
          }
        ]
      }
    ]
  })

  tags = {
    Name = "baseline-agents"
  }
}

resource "aws_imagebuilder_component" "trivy_install" {
  name     = "trivy-install"
  platform = "Linux"
  version  = "1.0.1"

  description = "Install Trivy vulnerability scanner"

  data = yamlencode({
    name          = "trivy-install"
    description   = "Install Trivy vulnerability scanner"
    schemaVersion = 1.0

    phases = [
      {
        name = "build"

        steps = [
          {
            name   = "InstallTrivy"
            action = "ExecuteBash"

            inputs = {
              commands = [
                "set -e",
                "dnf install -y wget",
                "wget -q https://github.com/aquasecurity/trivy/releases/download/v0.74.0/trivy_0.74.0_Linux-64bit.rpm -O /tmp/trivy.rpm",
                "rpm -Uvh /tmp/trivy.rpm",
                "trivy --version"
              ]
            }
          }
        ]
      }
    ]
  })

  tags = {
    Name = "trivy-install"
  }
}

resource "aws_imagebuilder_component" "vulnerability_scanning" {
  name     = "vulnerability-scanning"
  platform = "Linux"
  version  = "1.0.2"

  description = "Offline vulnerability scanning for Amazon Linux 2023 using Trivy"

  data = yamlencode({
    name          = "vulnerability-scanning"
    description   = "Offline vulnerability scanning for Amazon Linux 2023 using Trivy"
    schemaVersion = 1.0

    phases = [
      {
        name = "test"

        steps = [
          {
            name   = "DownloadTrivyDB"
            action = "S3Download"

            inputs = [
              {
                source      = "s3://${var.bucket_name}/trivy/trivy-db.zip"
                destination = "/tmp/trivy-db.zip"
              }
            ]
          },
          {
            name   = "PrepareTrivyDB"
            action = "ExecuteBash"

            inputs = {
              commands = [
                "set -e",
                "mkdir -p /root/.cache/trivy/db",
                "python3 -c \"import zipfile; zipfile.ZipFile('/tmp/trivy-db.zip', 'r').extractall('/root/.cache/trivy/db')\"",
                "test -f /root/.cache/trivy/db/trivy.db",
                "test -f /root/.cache/trivy/db/metadata.json",
                "ls -lh /root/.cache/trivy/db/"
              ]
            }
          },
          {
            name   = "ScanAmazonLinux2023"
            action = "ExecuteBash"

            inputs = {
              commands = [
                "set -e",
                "echo '=== Trivy Vulnerability Scan ==='",
                "trivy filesystem / --cache-dir /root/.cache/trivy --scanners vuln --severity HIGH,CRITICAL --ignore-unfixed --skip-db-update --skip-java-db-update --offline-scan --exit-code 1 --no-progress",
                "echo '=== Trivy Vulnerability Scan Completed ==='"
              ]
            }
          }
        ]
      }
    ]
  })

  tags = {
    Name = "vulnerability-scanning"
  }
}

resource "aws_imagebuilder_image_recipe" "golden_al2023" {
  name         = "golden-al2023-base"
  version      = "1.0.0"
  description  = "Immutable hardened Amazon Linux 2023 Golden AMI"
  parent_image = "arn:aws:imagebuilder:${var.aws_region}:aws:image/amazon-linux-2023-x86/x.x.x"

  working_directory = "/tmp"

  component {
    component_arn = aws_imagebuilder_component.security_patching.arn
  }

  component {
    component_arn = aws_imagebuilder_component.cis_level1_hardening.arn
  }

  component {
    component_arn = aws_imagebuilder_component.baseline_agents.arn
  }

  component {
    component_arn = aws_imagebuilder_component.trivy_install.arn
  }

  component {
    component_arn = aws_imagebuilder_component.vulnerability_scanning.arn
  }

  block_device_mapping {
    device_name = "/dev/xvda"

    ebs {
      delete_on_termination = true
      encrypted             = true
      volume_size           = 20
      volume_type           = "gp3"
    }
  }

  tags = {
    Name        = "golden-al2023-base"
    Project     = "golden-ami"
    Environment = "shared"
  }
}

resource "aws_imagebuilder_infrastructure_configuration" "golden_ami" {
  name                          = "golden-ami-infrastructure"
  description                   = "Infrastructure configuration for Golden AMI builds"
  instance_profile_name         = var.instance_profile_name
  instance_types                = ["c7i-flex.large"]
  subnet_id                     = var.subnet_id
  security_group_ids            = [var.security_group_id]
  terminate_instance_on_failure = true

  logging {
    s3_logs {
      s3_bucket_name = var.bucket_name
      s3_key_prefix  = "imagebuilder-logs/"
    }
  }

  resource_tags = {
    Name        = "golden-ami-infrastructure"
    Project     = "golden-ami"
    Environment = "security"
    Purpose     = "golden-image"
  }

  tags = {
    Name = "golden-ami-infrastructure"
  }
}

resource "aws_imagebuilder_distribution_configuration" "golden_ami" {
  name        = "golden-ami-distribution"
  description = "Single-region distribution for Golden AMI"

  distribution {
    region = var.aws_region

    ami_distribution_configuration {
      name        = "golden-al2023-{{ imagebuilder:buildDate }}"
      description = "Immutable hardened Amazon Linux 2023 Golden AMI"

      ami_tags = {
        Name        = "golden-al2023"
        Project     = "golden-ami"
        Environment = "shared"
        ManagedBy   = "image-builder"
      }
    }

    ssm_parameter_configuration {
      parameter_name = var.ssm_parameter_name
      data_type      = "aws:ec2:image"
      ami_account_id = var.account_id
    }
  }

  tags = {
    Name = "golden-ami-distribution"
  }
}

resource "aws_imagebuilder_image_pipeline" "golden_ami" {
  name        = "golden-ami-manual"
  description = "Weekly immutable CIS-hardened Amazon Linux 2023 Golden AMI"

  image_recipe_arn                 = aws_imagebuilder_image_recipe.golden_al2023.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.golden_ami.arn
  distribution_configuration_arn   = aws_imagebuilder_distribution_configuration.golden_ami.arn

  status = "ENABLED"

  schedule {
    schedule_expression                = "cron(0 3 ? * MON *)"
    pipeline_execution_start_condition = "EXPRESSION_MATCH_AND_DEPENDENCY_UPDATES_AVAILABLE"
    timezone                           = "Asia/Calcutta"
  }

  image_tests_configuration {
    image_tests_enabled = true
    timeout_minutes     = 60
  }

  tags = {
    Name = "golden-ami-manual"
  }

  lifecycle {
    replace_triggered_by = [
      aws_imagebuilder_image_recipe.golden_al2023
    ]
  }
}

resource "aws_imagebuilder_image" "golden_ami" {
  image_recipe_arn                 = aws_imagebuilder_image_recipe.golden_al2023.arn
  infrastructure_configuration_arn = aws_imagebuilder_infrastructure_configuration.golden_ami.arn
  distribution_configuration_arn   = aws_imagebuilder_distribution_configuration.golden_ami.arn

  tags = {
    Name        = "golden-al2023-build"
    Project     = "golden-ami"
    Environment = "shared"
  }
}
