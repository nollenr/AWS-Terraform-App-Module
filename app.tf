resource "aws_instance" "app" {
  count                       = var.create_ec2_instances == "yes" ? 1 : 0
  user_data_replace_on_change = true
  tags                        = merge(local.tags, {Name = "${var.owner}-crdb-app-${count.index}"})
  ami                         = "${data.aws_ami.amazon_linux_2023_x64.id}"
  instance_type               = var.app_instance_type
  key_name                    = var.cluster_info["region"].aws_instance_key
  network_interface {
    # network_interface_id = data.aws_network_interface.details[count.index].id
    network_interface_id = aws_network_interface.app[count.index].id
    device_index = 0
  }
  root_block_device {
    delete_on_termination = true
    encrypted             = true
    volume_type           = "gp2"
    volume_size           = 8
  }
  #  To connect using the keys that have been created:
  #  cockroach-sql sql --url "postgres://192.168.4.103:26257/defaultdb?sslmode=verify-full&sslrootcert=$HOME/certs/ca.crt&sslcert=$HOME/certs/client.ron.crt&sslkey=$HOME/certs/client.ron.key"
user_data = join("\n", [
  # 1) Key management (SSH + certs/keys)
  templatefile("${path.module}/scripts/01_key_mgmt.sh", {
    admin_user       = local.admin_username
    tls_private_key  = local.tls_private_key
    tls_cert         = local.tls_cert
  }),
  # 2) Download & install CockroachDB binaries (also installs git/curl/tar)
  templatefile("${path.module}/scripts/02_install_crdb.sh", {
    crdb_version = var.crdb_version
  }),
  # 4) Install pgworkload (adds DBWORKLOAD_INSTALL() to admin's .bashrc)
  templatefile("${path.module}/scripts/04_install_pgworkload.sh", {
    admin_user = local.admin_username
  }),
  # 5) Install multi-region demo (adds MULTIREGION_DEMO_INSTALL() to admin's .bashrc)
  templatefile("${path.module}/scripts/05_install_demo.sh", {
    admin_user                 = local.admin_username
    include_demo               = var.include_demo  # "yes" or "no"
    database_connection_string = var.cluster_info["region"].database_connection_string
    database_regions           = join(",", var.crdb_region_list)
    app_private_ip_list = length(var.other_app_nodes) > 0 ? join(",", concat([for node in var.other_app_nodes : node.private_ip], [aws_network_interface.app[count.index].private_ip])) : ""
    app_public_ip_list  = join(",", [for node in var.other_app_nodes : node.public_ip])
  }),
])
}
