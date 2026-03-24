output "app_instance_ips" {
  description = "IP addresses of app instance"
  value = length(aws_instance.app) > 0 ? {
    private_ip = aws_instance.app[0].private_ip
    public_ip  = aws_instance.app[0].public_ip
  } : null
}
