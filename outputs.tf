output "vpc_id" {
  description = "ID of the VPC created by the module"
  value       = aws_vpc.main.id
}

output "security_group_intra_node_id" {
  description = "ID of the security group allowing intra-node communication"
  value = module.security-group-02.security_group_id
}

output "app_instance_ips" {
  description = "IP addresses of app instance"
  value = length(aws_instance.app) > 0 ? {
    private_ip = aws_instance.app[0].private_ip
    public_ip  = aws_instance.app[0].public_ip
  } : null
}
