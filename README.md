# AWS Terraform App Module

A Terraform module for deploying AWS infrastructure with CockroachDB application instances, including network setup, security groups, and automated provisioning. This module is designed to be called from [AWS-Terraform-App-Multi-Region](https://github.com/nollenr/AWS-Terraform-App-Multi-Region) for multi-region deployments.

## Overview

This Terraform module creates a complete AWS environment for running CockroachDB applications, featuring:

- **VPC Infrastructure**: VPC with public and private subnets across 3 availability zones
- **Security**: Security groups with configurable IP whitelisting and TLS certificate management
- **EC2 Instances**: Conditional deployment of Amazon Linux 2023 app instances with pre-created network interfaces
- **Automated Provisioning**: User data scripts that install CockroachDB, tooling, and optional demos
- **Multi-region Support**: Configuration for multi-region CockroachDB demonstrations with cross-region IP sharing

## Architecture

### Network Components

- 1 VPC with CIDR block specified via `cluster_info`
- 3 Public subnets (one per availability zone)
- 3 Private subnets (one per availability zone)
- Internet Gateway for public subnet connectivity
- Route tables for public and private subnets
- Pre-created network interfaces (allows private IP assignment before instance creation)

### Security Groups

- **SG-01**: Desktop access for SSH (22), RDP (3389), CockroachDB (26257), HTTP (8080), Grafana (3000), Prometheus (9090)
- **SG-02**: Intra-node communication (all traffic within security group)

### EC2 Instances

- Instance type: `t3a.micro` (configurable)
- AMI: Amazon Linux 2023 (x86_64)
- Network interface attached with private IP assigned at interface creation
- Automated installation of:
  - CockroachDB binaries
  - SSH keys and TLS certificates
  - pgworkload tool
  - Multi-region demo (optional)

## Prerequisites

- Terraform >= 1.2.0
- AWS CLI configured with appropriate credentials
- Existing EC2 key pairs in your AWS account (one per region)

## Variables

### Required Variables

- **`cluster_info`**: Map containing region-specific configuration

  ```hcl
  cluster_info = {
    region = {
      database_region_name       = string  # e.g., "aws-us-east-2"
      aws_region_name            = string  # e.g., "us-east-2"
      database_connection_string = string  # CockroachDB connection string
      aws_instance_key           = string  # EC2 key pair name
      vpc_cidr                   = string  # e.g., "192.168.3.0/24"
    }
  }
  ```

### Optional Variables

| Variable | Description | Default |
| -------- | ----------- | ------- |
| `project_name` | Name of the project | `terraform-test` |
| `owner` | Owner of the infrastructure | `` |
| `my_ip_address` | Your IP address for security group access | `0.0.0.0` |
| `create_ec2_instances` | Create EC2 instances (`yes`/`no`) | `yes` |
| `app_instance_type` | EC2 instance type | `t3a.micro` |
| `crdb_version` | CockroachDB version | `24.2.4` |
| `aws_region_01` | Primary AWS region | `us-east-2` |
| `aws_region_list` | List of AWS regions for multi-region demo | `["us-east-2", "us-west-2", "us-east-1"]` |
| `crdb_region_list` | List of CockroachDB regions for demo | `["us-east-2", "us-west-2", "us-east-1"]` |
| `include_demo` | Include multi-region demo (`yes`/`no`) | `no` |
| `other_app_nodes` | List of other app nodes' IPs (for primary node) | `[]` |
| `resource_tags` | Additional tags to apply to resources | `{}` |

### TLS Variables

Optional TLS certificate variables (auto-generated if not provided):

- `tls_private_key`
- `tls_public_key`
- `tls_cert`
- `tls_user_cert`
- `tls_user_key`

## Usage

### As a Module (Recommended)

This module is primarily used by [AWS-Terraform-App-Multi-Region](https://github.com/nollenr/AWS-Terraform-App-Multi-Region) for multi-region deployments. The parent module calls this module multiple times (once per region) to create a complete multi-region CockroachDB application infrastructure.

Example module call:

```hcl
module "app-region-1" {
  source = "github.com/nollenr/AWS-Terraform-App-Module.git"

  providers = {
    aws = aws.region-1
  }

  my_ip_address     = var.my_ip_address
  owner             = var.owner
  project_name      = var.project_name
  crdb_version      = var.crdb_version
  app_instance_type = var.app_instance_type
  include_demo      = var.include_demo

  cluster_info = {
    region = {
      database_region_name       = "aws-us-east-2"
      aws_region_name            = "us-east-2"
      database_connection_string = "postgresql://..."
      aws_instance_key           = "your-key-pair-name"
      vpc_cidr                   = "192.168.3.0/24"
    }
  }

  tls_private_key = tls_private_key.crdb_ca_keys.private_key_pem
  tls_public_key  = tls_private_key.crdb_ca_keys.public_key_pem
  tls_cert        = tls_self_signed_cert.crdb_ca_cert.cert_pem
}
```

### Standalone Deployment

1. **Create a `terraform.tfvars` file:**

   ```hcl
   owner             = "your-name"
   project_name      = "crdb-multi-region-iam-demo"
   my_ip_address     = "1.2.3.4"
   app_instance_type = "t3a.micro"
   crdb_version      = "25.2.5"
   include_demo      = "yes"

   cluster_info = {
     region = {
       database_region_name       = "aws-us-east-2"
       aws_region_name            = "us-east-2"
       database_connection_string = "postgresql://..."
       aws_instance_key           = "your-key-pair-name"
       vpc_cidr                   = "192.168.3.0/24"
     }
   }
   ```

2. **Initialize, plan, and apply:**

   ```bash
   terraform init
   terraform plan
   terraform apply
   ```

### Multi-Region Primary Node

For the primary node that needs IPs of other app nodes (e.g., for Prometheus scraping):

```hcl
module "app-region-0-primary" {
  source = "github.com/nollenr/AWS-Terraform-App-Module.git"

  # ... other variables ...

  other_app_nodes = [
    {
      private_ip = module.app-region-1.app_instance_ips.private_ip
      public_ip  = module.app-region-1.app_instance_ips.public_ip
    },
    {
      private_ip = module.app-region-2.app_instance_ips.private_ip
      public_ip  = module.app-region-2.app_instance_ips.public_ip
    }
  ]
}
```

The primary node will have environment variables set in `.bashrc`:

- `APP_PRIVATE_IP_LIST`: Comma-separated list of all app node private IPs (this node first)
- `APP_PUBLIC_IP_LIST`: Comma-separated list of other app node public IPs

### Network-Only Deployment

To create only the VPC and networking components without EC2 instances:

```hcl
create_ec2_instances = "no"
```

## Outputs

The module outputs the following information:

- `app_instance_ips`: Object containing private and public IPs of the app instance (if created)
  - `private_ip`: Private IP from the network interface
  - `public_ip`: Public IP assigned to the instance
- `vpc_id`: ID of the created VPC
- `security_group_intra_node_id`: ID of the intra-node communication security group
- `route_table_public_id`: ID of the public route table

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

```text
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
