# Golden AMI Pipeline — Immutable, Pre-Hardened Base Images

> **AWS DevOps / Cloud Security Project**  
> Terraform • EC2 Image Builder • Amazon Linux 2023 • SSM • Trivy • Auto Scaling • Lambda • EventBridge

An infrastructure-as-code implementation of an **immutable Golden AMI pipeline** for Amazon Linux 2023.

The project builds a standardized EC2 base image, applies security patches and a defined **CIS Level 1 hardening subset**, installs baseline management/monitoring agents, performs automated vulnerability validation with **Trivy**, publishes the resulting AMI, and rolls the AMI out to an Auto Scaling Group through a controlled **EC2 Instance Refresh**.

The infrastructure is provisioned and managed using **Terraform**.

---

## Architecture

```text
                         ┌──────────────────────┐
                         │     EventBridge       │
                         │   Scheduled Trigger   │
                         └──────────┬───────────┘
                                    │
                                    ▼
                    ┌──────────────────────────────┐
                    │       EC2 Image Builder      │
                    │                              │
                    │  Amazon Linux 2023           │
                    │          │                   │
                    │          ▼                   │
                    │  Security Patching           │
                    │          │                   │
                    │          ▼                   │
                    │  CIS Level 1 Hardening       │
                    │          │                   │
                    │          ▼                   │
                    │  Baseline Agents             │
                    │          │                   │
                    │          ▼                   │
                    │  Trivy Installation          │
                    │          │                   │
                    │          ▼                   │
                    │  Vulnerability Validation    │
                    └──────────────┬───────────────┘
                                   │
                              Validation Pass
                                   │
                                   ▼
                         ┌──────────────────┐
                         │   Golden AMI      │
                         │ Amazon Linux 2023 │
                         └─────────┬────────┘
                                   │
                    ┌──────────────┴──────────────┐
                    │                             │
                    ▼                             ▼
          ┌──────────────────┐          ┌──────────────────┐
          │ SSM Parameter    │          │ Launch Template  │
          │ Store            │          │ New Version      │
          │ /golden-ami/...  │          └────────┬─────────┘
          └──────────────────┘                   │
                                                 ▼
                                      ┌─────────────────────┐
                                      │ Lambda              │
                                      │ Rollout Controller   │
                                      └──────────┬──────────┘
                                                 │
                                                 ▼
                                      ┌─────────────────────┐
                                      │ Auto Scaling Group   │
                                      │                     │
                                      │ Instance Refresh    │
                                      └──────────┬──────────┘
                                                 │
                                                 ▼
                                      ┌─────────────────────┐
                                      │ New EC2 Instances   │
                                      │ using Golden AMI    │
                                      └─────────────────────┘
```

---

## Why Golden AMIs?

Traditional EC2 deployments often rely on a generic base AMI followed by instance-specific configuration through user data or configuration-management tooling.

That can create configuration drift:

```text
Generic AMI
    │
    ├── Instance A → configuration version 1
    ├── Instance B → configuration version 2
    └── Instance C → configuration version 3
```

This project follows an immutable-image approach:

```text
Hardened + Tested Golden AMI
            │
            ├── Instance A
            ├── Instance B
            └── Instance C
```

Every newly launched instance starts from the same validated image.

The goal is to move security and baseline configuration **into the image creation lifecycle**, rather than repeatedly configuring individual production instances.

---

# Project Goals

- Build standardized Amazon Linux 2023 Golden AMIs.
- Apply security updates during image creation.
- Implement a defined CIS Level 1 hardening subset.
- Install baseline management and monitoring agents.
- Perform automated HIGH/CRITICAL vulnerability validation.
- Store the latest AMI ID in SSM Parameter Store.
- Roll out new AMIs through Auto Scaling Instance Refresh.
- Keep Image Builder infrastructure private without a NAT Gateway.
- Manage the complete infrastructure using Terraform.
- Provide repeatable and versioned image builds.

---

# Technology Stack

| Area | Technology |
|---|---|
| Cloud | AWS |
| Region | `eu-west-2` — London |
| Infrastructure as Code | Terraform |
| Base OS | Amazon Linux 2023 |
| Image Management | EC2 Image Builder |
| Parameter Management | AWS Systems Manager Parameter Store |
| Vulnerability Scanner | Trivy |
| Management | AWS Systems Manager |
| Monitoring Agent | Amazon CloudWatch Agent |
| Compute | Amazon EC2 |
| Scaling | EC2 Auto Scaling |
| Deployment | EC2 Instance Refresh |
| Automation | AWS Lambda |
| Scheduling | Amazon EventBridge |
| Object Storage | Amazon S3 |
| Networking | Amazon VPC |
| Private AWS Connectivity | VPC Endpoints |
| IAM | IAM Roles and Policies |

---

# Infrastructure

The project provisions a dedicated VPC for the image-building environment.

```text
VPC
10.0.0.0/16
│
├── Public Subnet
│   └── 10.0.0.0/20
│
└── Private Subnet
    └── 10.0.128.0/20
        │
        ├── S3 Gateway Endpoint
        ├── SSM Interface Endpoint
        ├── SSMMessages Interface Endpoint
        └── EC2 Image Builder Interface Endpoint
```

The Image Builder build environment does **not** depend on a NAT Gateway.

AWS service connectivity required by the build environment is provided through VPC endpoints where supported.

This reduces unnecessary network exposure and avoids the recurring cost of a NAT Gateway.

---

# Image Build Pipeline

The Image Builder recipe contains the following components.

## 1. Security Patching

The image is updated using Amazon Linux package security updates:

```bash
dnf update --security -y
```

The objective is to ensure that the image does not begin its lifecycle with known package-level security updates waiting to be applied.

---

## 2. CIS Level 1 Hardening Subset

The project implements a defined subset of CIS-style Linux security controls.

Examples include:

- SELinux enforcement
- SELinux targeted policy
- SSH root-login restrictions
- SSH empty-password restrictions
- SSH authentication limits
- SSH session limits
- SSH logging configuration
- `sudo` PTY enforcement
- `sudo` logging
- password/shadow file permissions
- cron configuration
- crypto policy configuration
- kernel network hardening
- `ptrace` restrictions
- systemd core dump restrictions
- time synchronization
- service enablement

Validation is performed during the image build/test lifecycle.

> **Important:** This project does not claim complete CIS Level 1 certification or compliance. It implements a defined CIS Level 1 hardening subset with automated validation.

---

# Baseline Agents

The Golden AMI contains baseline management and monitoring components.

### AWS Systems Manager Agent

SSM Agent is validated and enabled:

```bash
rpm -q amazon-ssm-agent
systemctl is-enabled amazon-ssm-agent
```

### CloudWatch Agent

The Amazon CloudWatch Agent is installed and enabled for monitoring integration.

### EDR Integration Point

EDR deployment is intentionally treated as a vendor-specific integration point rather than embedding an arbitrary enterprise EDR product into the public project.

This allows the same Golden AMI architecture to integrate with an organization's selected EDR platform.

---

# Vulnerability Validation

The project uses **Trivy** as the vulnerability scanner.

The build performs an offline filesystem scan and evaluates:

```text
Severity:
HIGH
CRITICAL
```

The vulnerability gate is configured with:

```text
--ignore-unfixed
--offline-scan
--skip-db-update
--exit-code 1
```

The important behavior is the exit code:

```text
No matching HIGH/CRITICAL vulnerabilities
                │
                ▼
          Build continues
```

```text
HIGH/CRITICAL vulnerability detected
                │
                ▼
           Exit code 1
                │
                ▼
        Image validation fails
```

This prevents an image from being considered successfully validated when the configured vulnerability policy fails.

---

# Offline Trivy Database

The vulnerability scanning stage is designed to work without requiring the build instance to access the public internet.

The Trivy vulnerability database is staged in Amazon S3 and downloaded into the Image Builder test environment.

```text
S3
 │
 │ Trivy DB
 ▼
Image Builder Test Instance
 │
 ▼
Trivy Offline Scan
 │
 ├── PASS → AMI can continue
 │
 └── FAIL → Image build/test fails
```

This design fits the private Image Builder networking model.

---

# Golden AMI Publication

After the image passes its build and validation stages, EC2 Image Builder produces an AMI.

The latest AMI is exposed through Systems Manager Parameter Store:

```text
/golden-ami/al2023/latest
```

The parameter contains the current Golden AMI ID.

Example:

```text
/golden-ami/al2023/latest
        │
        ▼
ami-xxxxxxxxxxxxxxxxx
```

Using a stable parameter name avoids hard-coding a specific AMI ID throughout the deployment workflow.

---

# Automated AMI Rollout

The rollout process uses:

```text
SSM Parameter Store
        │
        ▼
Rollout Lambda
        │
        ▼
New Launch Template Version
        │
        ▼
Auto Scaling Group
        │
        ▼
EC2 Instance Refresh
        │
        ▼
New Instances
```

The Lambda retrieves the current AMI ID from SSM Parameter Store and creates a new Launch Template version containing the Golden AMI.

It then updates the Auto Scaling Group and starts an Instance Refresh.

AWS recommends Launch Templates for Auto Scaling, and Launch Templates support versioning, which allows different AMI configurations to be tracked.

EC2 Auto Scaling Instance Refresh is specifically designed for rolling out new AMIs or launch-template changes across an Auto Scaling Group.

---

# Instance Refresh Strategy

The implemented rollout uses controlled health settings rather than immediately terminating all existing instances.

Configured behavior includes:

```text
Minimum healthy percentage: 100%
Maximum healthy percentage: 110%
Instance warmup: 300 seconds
```

Conceptually:

```text
Old Instance
     │
     │
     ▼
New Golden AMI Instance
     │
     │ Health validation
     ▼
Healthy
     │
     ▼
Old Instance Removed
```

This reduces the risk of taking the Auto Scaling Group below its required healthy capacity during an image rollout.

AWS also supports checkpoints, bake time, skip matching, and rollback capabilities for more advanced production rollout strategies.

---

# Verification

After deployment, verify the major components.

### Image Builder

Check:

```text
EC2 → Image Builder → Images
```

Confirm that the image build completed successfully.

### SSM Parameter

Verify:

```text
/golden-ami/al2023/latest
```

The value should contain the latest validated AMI ID.

### AMI

Confirm that the AMI exists in:

```text
EC2 → AMIs
```

### Launch Template

Verify that the new launch-template version references the expected Golden AMI.

### Auto Scaling

Verify:

```text
EC2 → Auto Scaling Groups
```

Check:

- desired capacity
- healthy instances
- launch template version
- instance refresh status

### SSM

The launched instance should appear as:

```text
Online
```

in Systems Manager.

### Security Validation

On the resulting instance, validate the expected hardening configuration and installed baseline agents.

---

# Security Design

The project follows several security principles.

### Private Image-Building Environment

Image Builder runs in a private subnet.

### No NAT Gateway

The design intentionally avoids a NAT Gateway.

Required AWS service communication is handled through VPC endpoints where applicable.

### Least-Privilege IAM

Separate IAM roles are used for Image Builder, EC2 instances, Lambda functions, and scheduled operations.

### Immutable Infrastructure

Instances are replaced with new instances based on a validated AMI instead of modifying long-running instances in place.

### Automated Security Gate

The image validation process can fail when the configured HIGH/CRITICAL vulnerability policy is violated.

### No SSH Requirement

SSM provides management access without requiring inbound SSH access to the private image-building environment.

---

# Cost Considerations

This project was designed with AWS cost awareness in mind.

The following choices intentionally reduce recurring infrastructure cost:

- No NAT Gateway
- Private VPC endpoints where required
- Single AWS region
- Single-account implementation
- Small development/test Auto Scaling capacity
- Open-source Trivy instead of a paid vulnerability platform

However, AWS services used by the project can still incur charges.

Potential cost areas include:

- EC2 Image Builder build instances
- EC2 instances
- EBS volumes
- S3 storage and requests
- VPC interface endpoints
- Lambda execution
- CloudWatch logging
- EventBridge/Scheduler
- other AWS services depending on usage

Always review the AWS pricing for the services enabled in the account before running repeated image builds.

---

# Production Considerations

This implementation intentionally keeps the scope suitable for a single-account, single-region project while following production-oriented patterns.

A larger enterprise implementation could extend the design with:

```text
                    ┌─────────────────────┐
                    │ Central Image Account│
                    └──────────┬──────────┘
                               │
                  Cross-account AMI sharing
                               │
              ┌────────────────┼────────────────┐
              ▼                ▼                ▼
           Dev Account      Stage Account     Prod Account
```

Possible production extensions include:

- Cross-account AMI distribution
- Multi-region AMI distribution
- AWS Organizations integration
- Centralized security logging
- AWS Inspector integration
- Enterprise EDR integration
- Automated rollback
- Instance Refresh checkpoints
- CloudWatch alarm-based rollback
- AMI lifecycle cleanup
- Approval gates
- Image signing
- Central compliance reporting
- CI/CD integration
- Disaster recovery regions

These capabilities are intentionally outside the current single-account implementation.

---

# What This Project Demonstrates

This project demonstrates practical experience with:

- AWS EC2 Image Builder
- Immutable infrastructure
- Golden AMI design
- Amazon Linux security hardening
- CIS-oriented security controls
- Vulnerability scanning
- Trivy
- AWS Systems Manager
- SSM Parameter Store
- AWS VPC
- Private subnets
- VPC endpoints
- IAM
- Terraform
- AWS Lambda
- EventBridge
- EC2 Launch Templates
- Auto Scaling Groups
- Instance Refresh
- Security-focused infrastructure automation

---

# Design Trade-offs

## Why Golden AMI instead of User Data?

User Data is useful for instance-specific configuration, but security baselines and common dependencies can be baked into a reusable image.

This reduces configuration work during instance startup and provides a consistent starting point.

## Why Terraform?

The infrastructure contains networking, IAM, Image Builder, Lambda, Auto Scaling, and scheduling resources.

Terraform makes these resources reproducible and version-controlled.

## Why Trivy?

Trivy provides an open-source vulnerability scanning solution suitable for the project without requiring a paid security platform.

## Why no NAT Gateway?

The image-building environment does not require general outbound internet access for the intended architecture. Avoiding NAT also reduces recurring infrastructure cost.

## Why SSM Parameter Store?

The rollout mechanism needs a stable reference to the latest Golden AMI rather than embedding an AMI ID throughout the infrastructure.

## Why Instance Refresh?

Replacing instances through Auto Scaling allows the new AMI to be rolled out progressively instead of manually rebuilding individual EC2 instances.

---

# Limitations

This repository is intentionally scoped.

### Not included

- Full CIS Level 1 compliance certification
- Cross-account AMI distribution
- Multi-region AMI replication
- Paid vulnerability-management platforms
- Enterprise EDR vendor integration
- Production-scale multi-AZ capacity
- Destructive automated AMI deletion
- Enterprise approval workflows

The project should therefore be described as a **production-oriented reference implementation**, not a complete enterprise image-management platform.

---

# Key Outcome

The final workflow is:

```text
Security Patch
      ↓
OS Hardening
      ↓
Baseline Agents
      ↓
Vulnerability Validation
      ↓
Golden AMI
      ↓
SSM Parameter Store
      ↓
Launch Template Version
      ↓
Auto Scaling Group
      ↓
Instance Refresh
      ↓
New Hardened Instances
```

The result is a repeatable workflow where **new EC2 capacity is launched from a tested and security-hardened image rather than being configured from scratch after launch**.

---

# Author

**Ayush Trivedi**

DevOps / Cloud Engineer

Focus areas:

```text
AWS • Terraform • Linux • CI/CD • DevOps • Cloud Security
```
