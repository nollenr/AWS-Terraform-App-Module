# ----------------------------------------
# TAGS
# ----------------------------------------
    # Required tags
    variable "project_name" {
      description = "Name of the project."
      type        = string
      default     = "terraform-test"
    }

    variable "owner" {
      description = "Owner of the infrastructure"
      type        = string
      default     = ""
    }

    # Optional tags
    variable "resource_tags" {
      description = "Tags to set for all resources"
      type        = map(string)
      default     = {}
    }

# ----------------------------------------
# My IP Address
# This is used in the creation of the security group 
# and will allow access to the ec2-instances on ports
# 22 (ssh), 26257 (database), 8080 (for observability)
# and 3389 (rdp)
# ----------------------------------------
    variable "my_ip_address" {
      description = "User IP address for access to the ec2 instances."
      type        = string
      default     = "0.0.0.0"
    }

# ----------------------------------------
# Create EC2 Instances
# ----------------------------------------
  variable "create_ec2_instances" {
    description = "create the ec2 instances (yes/no)?  If set to 'no', then only the VPC, subnets, routes tables, routes, peering, etc are created"
    type = string
    default = "yes"
    validation {
      condition = contains(["yes", "no"], var.create_ec2_instances)
      error_message = "Valid value for variable 'create_ec2_instances' is : 'yes' or 'no'"        
    }
  }

# ----------------------------------------
# APP Instance Specifications
# ----------------------------------------
  variable "app_instance_type" {
    description = "App Instance Type"
    type        = string
    default     = "t3a.micro"
  }
  variable "crdb_version" {
    description = "CockroachDB Version"
    type        = string
    default     = "24.2.4"
  }

# ----------------------------------------
# Regions
# ----------------------------------------
  # Needed for the multi-region-demo
  variable "aws_region_01" {
    description = "AWS region"
    type        = string
    default     = "us-east-2"
  }
  # This is not used except for the mult-region-demo function being added to the bashrc
  variable "aws_region_list" {
    description = "list of the AWS regions for the crdb cluster"
    type = list
    default = ["us-east-2", "us-west-2", "us-east-1"]
  }

# ----------------------------------------
# Demo
# ----------------------------------------
    variable "include_demo" {
      description = "'yes' or 'no' to include an HAProxy Instance"
      type        = string
      default     = "no"
      validation {
        condition = contains(["yes", "no"], var.include_demo)
        error_message = "Valid value for variable 'include_demo' is : 'yes' or 'no'"        
      }
    }

# ----------------------------------------
# TLS Vars -- Leave blank to have then generated
# ----------------------------------------
  variable "tls_private_key" {
    description = "tls_private_key.crdb_ca_keys.private_key_pem -> ca.key / TLS Private Key PEM"
    type        = string
    default     = ""
 }

  variable "tls_public_key" {
    description = "tls_private_key.crdb_ca_keys.public_key_pem -> ca.pub / TLS Public Key PEM"
    type        = string
    default     = ""
  }

  variable "tls_cert" {
    description = "tls_self_signed_cert.crdb_ca_cert.cert_pem -> ca.crt / TLS Cert PEM"
    type        = string
    default     = ""
  }

  variable "tls_user_cert" {
    description = "tls_locally_signed_cert.user_cert.cert_pem -> client.name.crt"
    type        = string
    default     = ""
  }

  variable "tls_user_key" {
    description = "tls_private_key.client_keys.private_key_pem -> client.name.key"
    type        = string
    default     = ""
  }


variable "cluster_info" {
  description = "Cluster configuration for each region"
  type = map(object({
    database_region_name       = string
    aws_region_name            = string
    database_connection_string = string
    aws_instance_key           = string
    vpc_cidr                   = string
  }))
}

# ----------------------------------------
# Other App Nodes (for multi-region setup)
# ----------------------------------------
variable "other_app_nodes" {
  description = "List of other app nodes' IP addresses (for multi-region primary node)"
  type = list(object({
    private_ip = string
    public_ip  = string
  }))
  default = []
}