owner = "nollen"
project_name = "crdb-multi-region-iam-demo"
my_ip_address = "98.148.51.154"
app_instance_type = "t3a.micro"
instance_key_name = "nollen-cockroach-revenue-us-east-2-kp01"
crdb_version = "25.2.5"
include_demo = "yes"             # setting this to yes in a single-region cluster is not really valid.  software will be installed, but database schema will not be created (creating will fail)
