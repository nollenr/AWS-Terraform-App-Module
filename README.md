# AWS Terraform App Module

A Terraform configuration for deploying AWS infrastructure with CockroachDB application instances, including network setup, security groups, and automated provisioning.

## Overview

This Terraform module creates a complete AWS environment for running CockroachDB applications, featuring:

- **VPC Infrastructure**: VPC with public and private subnets across 3 availability zones
- **Security**: Security groups with configurable IP whitelisting and TLS certificate management
- **EC2 Instances**: Conditional deployment of Amazon Linux 2023 app instances
- **Automated Provisioning**: User data scripts that install CockroachDB, tooling, and optional demos
- **Multi-region Support**: Configuration for multi-region CockroachDB demonstrations

## Architecture

### Network Components
- 1 VPC with customizable CIDR block (default: `192.168.4.0/24`)
- 3 Public subnets (one per availability zone)
- 3 Private subnets (one per availability zone)
- Internet Gateway for public subnet connectivity
- Route tables for public and private subnets

### Security Groups
- **SG-01**: Desktop access for SSH (22), RDP (3389), CockroachDB (26257), HTTP (8080), Grafana (3000), Prometheus (9090)
- **SG-02**: Intra-node communication (all traffic within security group)

### EC2 Instances
- Instance type: `t3a.micro` (configurable)
- AMI: Amazon Linux 2023 (x86_64)
- Automated installation of:
  - CockroachDB binaries
  - SSH keys and TLS certificates
  - pgworkload tool (optional)
  - Multi-region demo (optional)

## Prerequisites

- Terraform >= 1.2.0
- AWS CLI configured with appropriate credentials
- An existing EC2 key pair in your AWS account

## Variables

### Required Variables
- `instance_key_name`: Name of an existing EC2 key pair

### Optional Variables
| Variable | Description | Default |
|----------|-------------|---------|
| `vpc_cidr` | CIDR block for the VPC | `192.168.4.0/24` |
| `project_name` | Name of the project | `terraform-test` |
| `owner` | Owner of the infrastructure | `` |
| `my_ip_address` | Your IP address for security group access | `0.0.0.0` |
| `create_ec2_instances` | Create EC2 instances (`yes`/`no`) | `yes` |
| `app_instance_type` | EC2 instance type | `t3a.micro` |
| `crdb_version` | CockroachDB version | `24.2.4` |
| `aws_region_01` | Primary AWS region | `us-east-2` |
| `aws_region_list` | List of regions for multi-region demo | `["us-east-2", "us-west-2", "us-east-1"]` |
| `include_demo` | Include multi-region demo (`yes`/`no`) | `no` |

### TLS Variables
Optional TLS certificate variables (auto-generated if not provided):
- `tls_private_key`
- `tls_public_key`
- `tls_cert`
- `tls_user_cert`
- `tls_user_key`

## Usage

### Basic Deployment

1. **Initialize Terraform:**
   ```bash
   terraform init
   ```

2. **Create a `terraform.tfvars` file:**
   ```hcl
   owner               = "your-name"
   my_ip_address       = "1.2.3.4"
   instance_key_name   = "your-key-pair-name"
   create_ec2_instances = "yes"
   ```

3. **Plan the deployment:**
   ```bash
   terraform plan
   ```

4. **Apply the configuration:**
   ```bash
   terraform apply
   ```

### Network-Only Deployment

To create only the VPC and networking components without EC2 instances:

```hcl
create_ec2_instances = "no"
```

## Outputs

The module outputs the following information:

- `app_instance_ips`: Object containing private and public IPs of the app instance (if created)

View outputs after deployment:
```bash
terraform output
```

## Provisioning Scripts

The module includes automated provisioning scripts executed via user data:

1. **01_key_mgmt.sh**: Sets up SSH keys and TLS certificates in `/home/ec2-user/.ssh` and `/home/ec2-user/certs`
2. **02_install_crdb.sh**: Downloads and installs CockroachDB binaries to `/usr/local/bin`
3. **04_install_pgworkload.sh**: Installs pgworkload tool for database load testing
4. **05_install_demo.sh**: Installs multi-region demo application (if `include_demo = "yes"`)

## Network Security

The module includes IP whitelisting for Netskope tunneling by default. The following CIDR ranges are automatically allowed:
- `8.36.116.0/24`
- `8.39.144.0/24`
- `31.186.239.0/24`
- `163.116.128.0/17`
- `162.10.0.0/17`

Your specified `my_ip_address` is also added to the whitelist.

## Clean Up

To destroy all resources:

```bash
terraform destroy
```

## File Structure

```
.
├── app.tf              # EC2 app instance configuration
├── main.tf             # Provider, data sources, and locals
├── network.tf          # VPC, subnets, route tables, security groups
├── outputs.tf          # Output definitions
├── terraform.tf        # Terraform and provider version constraints
├── tls.tf              # TLS certificate generation
├── variables.tf        # Variable definitions
└── scripts/
    ├── 01_key_mgmt.sh
    ├── 02_install_crdb.sh
    ├── 04_install_pgworkload.sh
    └── 05_install_demo.sh
```

## Notes

- The module uses Amazon Linux 2023 AMI, which is automatically selected based on the latest available version
- TLS certificates are automatically generated using Terraform's TLS provider if not explicitly provided
- All resources are tagged with `owner` and `project` for easy identification and cost tracking
- EC2 instances use encrypted EBS volumes (gp2, 8GB) with deletion on termination enabled
