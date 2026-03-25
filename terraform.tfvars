owner = "nollen"
project_name = "crdb-multi-region-iam-demo"
my_ip_address = "98.148.51.154"
app_instance_type = "t3a.micro"
crdb_version = "25.2.5"
include_demo = "yes"             # setting this to yes in a single-region cluster is not really valid.  software will be installed, but database schema will not be created (creating will fail)


cluster_info = {
  region = {
    database_region_name       = "aws-us-east-2"
    aws_region_name            = "us-east-2"
    database_connection_string = "postgresql://ron@nollen-iam-demo-w7v.aws-us-east-2.cockroachlabs.cloud:26257/iam_demo?sslmode=verify-full&sslrootcert=$HOME/Library/CockroachCloud/certs/1d4d68ed-a173-461e-a522-4fbca2b062e1/nollen-iam-demo-ca.crt"
    aws_instance_key           = "nollen-cockroach-revenue-us-east-2-kp01"
    vpc_cidr                   = "192.168.3.0/24"
  }
}

other_app_nodes = []
crdb_region_list = []