output "vpc_id" {
  description = "ID of the VPC created by the module"
  value       = aws_vpc.main.id
}

output "security_group_intra_node_id" {
  description = "ID of the security group allowing intra-node communication"
  value = module.security-group-02.security_group_id
}

output "route_table_public_id" {
  description = "ID of the public route table"
  value = aws_route_table.public_route_table.id
}

output "app_instance_ips" {
  description = "IP addresses of app instance"
  value = var.create_ec2_instances == "yes" ? {
    private_ip = aws_network_interface.app[0].private_ip
    public_ip  = aws_instance.app[0].public_ip
  } : null
}
